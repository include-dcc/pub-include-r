
<!-- README.md is generated from README.Rmd. Please edit that file -->

# INCLUDE Shiny Template

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
<!-- badges: end -->

Welcome to INCLUDE. This repository will serve as a guide for developing
shiny applications and contains the most basic golem shiny application
structure. Here were the steps that went into creating this repository.

1.  Create Golem Shiny App: `golem::create_golem()` as documented
    [here](https://engineering-shiny.org/setting-up-for-success.html#create-a-golem)
2.  Utilize
    [renv](https://engineering-shiny.org/build-yourself-safety-net.html#renv)
    to set up your R environment
3.  Update readme by modifying README.Rmd (not README.md):

<!-- end list -->

    devtools::build_readme()

1.  Add golem modules. More information
    [here](https://engineering-shiny.org/build-app-golem.html#submodules-and-utility-functions)

<!-- end list -->

    golem::add_module( name = "hello_world" )

1.  Add tests. More information
    [here](https://engineering-shiny.org/build-app-golem.html#add-tests)

<!-- end list -->

    usethis::use_test( "app" )

## Installation

You can install the released version of includeshinytemplate from
[CRAN](https://CRAN.R-project.org) with:

``` r
install.packages("includeshinytemplate")
```

And the development version from [GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("include-dcc/include-shiny-template")
```

## Example

This is a basic example which shows you how to solve a common problem:

``` r
library(includeshinytemplate)
#> Error in get(genname, envir = envir) : object 'testthat_print' not found
## basic example code
```
