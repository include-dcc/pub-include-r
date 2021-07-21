"""PubMed Crawler of CSBC/PS-ON Publications.

author: nasim.sanati
author: milen.nikolov
author: verena.chung
"""
import os
import re
import argparse
import getpass
import ssl
from datetime import datetime
import requests

from Bio import Entrez
from bs4 import BeautifulSoup
import synapseclient
import pandas as pd
from alive_progress import alive_bar


def login():
    """Log into Synapse. If cached info not found, prompt user.

    Returns:
        syn: Synapse object
    """
    try:
        syn = synapseclient.login(silent=True)
    except Exception:
        print("Cached credentials not found; please provide",
              "your Synapse username and password.")
        username = input("Synapse username: ")
        password = getpass.getpass("Synapse password: ").encode("utf-8")
        syn = synapseclient.login(
            username=username, password=password,
            rememberMe=True, silent=True)
    return syn


def get_args():
    """Set up command-line interface and get arguments."""

    parser = argparse.ArgumentParser(
        description="Scrap PubMed information from a list of grant numbers"
        + " and put the results into a CSV file.  Table ID can be provided"
        + " if interested in only scrapping for new publications.")

    # TODO: default to the grants table/view in the "CSBC PS-ON DB" project
    parser.add_argument("-g", "--grantview_id",
                        type=str, default="syn21918972",
                        help="Synapse table/view ID containing grant numbers in"
                        + " 'grantNumber' column. (Default: syn21918972)")
    parser.add_argument("-t", "--table_id",
                        type=str,
                        help="Current Synapse table holding PubMed info.")
    parser.add_argument("-f", "--table_file",
                        type=str,
                        help="Local file table holding PubMed info.")
    parser.add_argument("-o", "--output",
                        type=str, default="publications_"
                        + datetime.today().strftime('%m-%d-%Y'),
                        help="Filename for output CSV. (Default:"
                        + " publications_<current-date>)")
    return parser.parse_args()


def get_view(syn, table_id):
    """Get Synapse table/data view containing grant numbers.

    Assumptions:
        Syanpse table/view has column called 'grantNumber'

    Returns:
        dataframe: consortiums and their project descriptions.
    """

    results = syn.tableQuery(
        f"select * from {table_id}").asDataFrame()
    return results[~results['grantNumber'].isnull()]


def get_grants(df):
    """Get list of grant numbers from dataframe.

    Assumptions:
        Dataframe has column called 'grantNumber'

    Returns:
        set: valid grant numbers, e.g. non-empty strings
    """

    print(f"Querying for grant numbers...", end="")
    grants = set(df.grantNumber.dropna())
    print(f"{len(grants)} found\n")
    return list(sorted(grants))


def get_pmids(grants, year_start=2018, year_end=2021):
    """Get list of PubMed IDs using grant numbers as search param.

    Returns:
        set: PubMed IDs
    """
    print("Getting PMIDs from NCBI...")
    all_pmids = set()

    # Brian's request: add check that pubs. are retreived for each grant number
    count = 1
    for grant in grants:
        print(f"  {count:02d}. Grant number {grant}...", end="")
        handle = Entrez.esearch(db="pubmed", term=grant,
                                datetype="pdat", mindate=year_start, maxdate=year_end,
                                retmax=1_000_000, retmode="xml", sort="relevance")
        pmids = Entrez.read(handle).get('IdList')
        handle.close()
        all_pmids.update(pmids)
        print(f"{len(pmids)} found")
        count += 1
    print(f"Total unique publications: {len(all_pmids)}\n")
    return all_pmids


def parse_header(header):
    """Parse header div for pub. title, authors journal, year, and doi."""
    # TITLE
    title = header.find('h1').text.strip()

    # JOURNAL
    journal = header.find('button').text.strip()

    # PUBLICATION YEAR
    pub_date = header.find('span', attrs={'class': "cit"}).text
    year = re.search(r"(\d{4}).*?[\.;]", pub_date).group(1)

    # DOI
    doi_cit = header.find(attrs={'class': "citation-doi"})
    doi = doi_cit.text.strip().lstrip("doi: ").rstrip(".") if doi_cit else ""

    # AUTHORS
    authors = [parse_author(a) for a in header.find_all(
        'span', attrs={'class': "authors-list-item"})]
    authors = [a for a in authors if a]

    return (title, journal, year, doi, authors)


def parse_author(item):
    """Parse author name from HTML 'author-list-item"""
    try:
        author = item.find('a', attrs={'class': "full-name"}).text
    except AttributeError:
        author = item.find('span', attrs={'class': "full-name"}).text
    return author


def parse_grant(grant):
    """Parse for grant number from grant annotation."""
    if len(grant):
        grant = re.sub(r'RO', 'R0', grant)
        grant_info = re.search(r"([A-Z][A-Z](\s|-)*\d{3,})[ /-]", grant, re.I)
        if grant_info is not None:
            grant_number = grant_info.group(1).upper()
            return re.sub(r'(\s|-)', '', grant_number)


def get_related_info(pmid):
    """Get related information associated with publication.

    Entrez will be used for optimal retrieval (since NCBI will kick
    us out if we web-scrap too often).

    Returns:
        dict: XML results for GEO, SRA, and dbGaP
    """
    handle = Entrez.elink(dbfrom="pubmed", db="gds,sra,gap", id=pmid,
                          remode="xml")
    results = Entrez.read(handle)[0].get('LinkSetDb')
    handle.close()

    related_info = {}
    for result in results:
        db = re.search(r"pubmed_(.*)", result.get('LinkName')).group(1)
        ids = [link.get('Id') for link in result.get('Link')]

        handle = Entrez.esummary(db=db, id=",".join(ids))
        soup = BeautifulSoup(handle, "lxml")
        handle.close()
        related_info[db] = soup

    return related_info


def parse_geo(info):
    """Parse and return GSE IDs."""
    gse_ids = []
    if info:
        tags = info.find_all('item', attrs={'name': "GSE"})
        gse_ids = ["GSE" + tag.text for tag in tags]
    return gse_ids


def parse_sra(info):
    """Parse and return SRX/SRP IDs."""

    srx_ids = srp_ids = []
    if info:
        tags = info.find_all('item', attrs={'name': "ExpXml"})
        srx_ids = [re.search(r'Experiment acc="(.*?)"', tag.text).group(1)
                   for tag in tags]
        srp_ids = {re.search(r'Study acc="(.*?)"', tag.text).group(1)
                   for tag in tags}
    return srx_ids, srp_ids


def parse_dbgap(info):
    """Parse and return study IDs."""
    gap_ids = []
    if info:
        tags = info.find_all('item', attrs={'name': "d_study_id"})
        gap_ids = [tag.text for tag in tags]
    return gap_ids


def make_urls(url, accessions):
    """Create NCBI link for each accession in the iterable.

    Returns:
        str: list of URLs
    """
    url_list = [url + accession for accession in list(accessions)]
    return ", ".join(url_list)


def scrape_info(pmids, curr_grants, grant_view):
    """Create dataframe of publications and their pulled data.

    Returns:
        df: publications data
    """
    columns = ["doi", "journal", "pubMedId", "pubMedUrl",
               "publicationTitle", "publicationYear", "keywords",
               "authors", "grantNumber",
               "gseAccns", "gseUrls", "srxAccns", "srxUrls",
               "srpAccns", "srpUrls", "dbgapAccns", "dbgapUrls"]

    if not os.environ.get('PYTHONHTTPSVERIFY', '') \
            and getattr(ssl, '_create_unverified_context', None):
        ssl._create_default_https_context = ssl._create_unverified_context

    table = []
    with alive_bar(len(pmids)) as progress:
        for pmid in pmids:
            session = requests.Session()
            url = f"https://www.ncbi.nlm.nih.gov/pubmed/?term={pmid}"
            soup = BeautifulSoup(session.get(url).content, "lxml")

            # HEADER
            # Contains: title, journal, pub. date, authors, pmid, doi
            header = soup.find(attrs={'id': "full-view-heading"})

            # PubMed utilizes JavaScript now, so content does not always
            # fully load on the first try.
            if not header:
                soup = BeautifulSoup(session.get(url).content, "lxml")
                header = soup.find(attrs={'id': "full-view-heading"})

            title, journal, year, doi, authors = parse_header(header)
            authors = ", ".join(authors)

            # GRANTS
            try:
                grants = [g.text.strip() for g in soup.find(
                    'div', attrs={'id': "grants"}).find_all('a')]
    
                # Filter out grant annotations not in consortia.
                grants = {parse_grant(grant) for grant in grants}
                          # if re.search(r"CA\d", grant, re.I)}
                grants = list(filter(lambda x: x in curr_grants, grants))
            except AttributeError:
                grants = []

            # KEYWORDS
            abstract = soup.find(attrs={"id": "abstract"})
            try:
                keywords = abstract.find(text=re.compile(
                    "Keywords")).find_parent("p").text.replace(
                    "Keywords:", "").strip()
            except AttributeError:
                keywords = ""

            # RELATED INFORMATION
            # Contains: GEO, SRA, dbGaP
            related_info = get_related_info(pmid)

            gse_ids = parse_geo(related_info.get('gds'))
            gse_url = make_urls(
                "https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=", gse_ids)

            srx, srp = parse_sra(related_info.get('sra'))
            srx_url = make_urls("https://www.ncbi.nlm.nih.gov/sra/", srx)
            srp_url = make_urls(
                "https://trace.ncbi.nlm.nih.gov/Traces/sra/?study=", srp)

            dbgap = parse_dbgap(related_info.get('gap'))
            dbgap_url = make_urls(
                "https://www.ncbi.nlm.nih.gov/projects/gap/cgi-bin/study.cgi?study_id=", 
                dbgap
            )

            row = pd.DataFrame(
                [[doi, journal, pmid, url, title, year, keywords, authors,
                  grants, gse_ids, gse_url,
                  srx, srx_url, list(srp), srp_url, dbgaps, dbgap_url]],
                columns=columns)
            table.append(row)
            session.close()
            # Save table
            tmp_tbl = pd.concat(table)
            tmp_tbl.to_csv("pubs_tmp.tsv", index=False, sep="\t", encoding="utf-8")

            # Increment progress bar animation.
            progress()

    return pd.concat(table)


def find_publications(syn, args):
    """Get list of publications based on grants of consortia."""
    grant_view = get_view(syn, args.grantview_id)
    grants = get_grants(grant_view)
    pmids = get_pmids(grants)

    # If user provided a table ID, only scrap info from
    # publications not already listed in the provided table.
    if args.table_id:
        print(f"Comparing with table {args.table_id}...")
        current_publications = syn.tableQuery(
            f"select * from {args.table_id}").asDataFrame()
        current_pmids = {re.search(r"[/=](\d+)$", i).group(1)
                         for i in list(current_publications.pubMedUrl)}
        pmids -= current_pmids
        print(f"  New publications found: {len(pmids)}\n")

    # If user provided a table file, only scrap info from
    # publications not already listed in the provided table.
    if args.table_file:
        print(f"Comparing with table {args.table_file}...")
        current_publications = pd.read_csv(args.table_file, sep='\t')
        current_pmids = {re.search(r"[/=](\d+)$", i).group(1)
                         for i in list(current_publications.pubMedUrl)}
        pmids -= current_pmids
        print(f"  New publications found: {len(pmids)}\n")

    print(f"Pulling information from publications...")

    table = scrape_info(sorted(pmids), grants, grant_view)
    table.to_csv(args.output + ".tsv", index=False, sep="\t", encoding="utf-8")
    print("DONE")


def main():
    """Main function."""
    syn = login()
    args = get_args()

    # In order to make >3 Entrez requests/sec, 'email' and 'api_key'
    # params need to be set.
    Entrez.email = os.getenv('ENTREZ_EMAIL')
    Entrez.api_key = os.getenv('ENTREZ_API_KEY')

    find_publications(syn, args)


if __name__ == "__main__":
    main()
