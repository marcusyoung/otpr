[![Build Status](https://travis-ci.org/marcusyoung/otpr.svg?branch=master)](https://travis-ci.org/marcusyoung/otpr)

# otpr

otpr is an R package that provides a simple wrapper for the OpenTripPlanner (OTP) API.
To use otpr you will need a running instance of OTP.

The purpose of the package is to submit a query to the relevant OTP API resource, parse
the OTP response and return useful R objects. It is left to the discretion of the user to,
for example, structure and process multiple queries in any desired fashion. Examples of how
to populate an origin-destination matrix are provided in my tutorial:

*OpenTripPlanner Tutorial - creating and querying your own multi-modal route planner*

[https://github.com/marcusyoung/otp-tutorial](https://github.com/marcusyoung/otp-tutorial). 

## Installation

Install the package with **devtools** as follows:

```{r install, eval=FALSE}
# install.packages("devtools")
devtools::install_github("marcusyoung/otpr")
```

## Status

Functions `otp_connect`, `otp_get_distance`, `otp_get_times` and `otp_get_isochrone` are currently implemented. Use help(?) for further guidance.

The package is under development but this only takes place on development branches. The master
branch is considered stable.
