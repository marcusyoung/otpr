<!-- README.md is generated from README.Rmd. Please edit that file -->

otpr <img src='man/figures/sticker.png' align="right" height=250/>
==================================================================

<!-- badges: start -->

[![Build
Status](https://travis-ci.org/marcusyoung/otpr.svg?branch=master)](https://travis-ci.org/marcusyoung/otpr)
[![CRAN
status](https://www.r-pkg.org/badges/version/otpr)](https://cran.r-project.org/package=otpr)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.4065250.svg)](https://doi.org/10.5281/zenodo.4065250)
[![Codecov test
coverage](https://codecov.io/gh/marcusyoung/otpr/branch/master/graph/badge.svg)](https://codecov.io/gh/marcusyoung/otpr?branch=master)
[![CRAN
downloads](https://cranlogs.r-pkg.org/badges/grand-total/otpr)](https://cran.r-project.org/package=otpr)
[![Project Status: Active – The project has reached a stable, usable
state and is being actively
developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
<!-- badges: end -->

Overview
--------

**otpr** is an R package that provides a wrapper for the
[OpenTripPlanner](https://www.opentripplanner.org/) (OTP) API. To use
**otpr** you will need a running instance of OTP. The purpose of the
package is to submit a query to the relevant OTP API resource, parse the
OTP response and return useful R objects. The package is aimed at both
new and expert users of OTP. The key parameters needed to query each
supported API resource are provided as (or via) **otpr** function
arguments. The argument values submitted by the user are comprehensively
checked prior to submission to OTP to ensure that they are valid and
make sense in combination, with feedback provided as appropriate. This
makes the package ideal for new users of OTP (especially when used with
the [accompanying
tutorial](https://github.com/marcusyoung/otp-tutorial)). Advanced users
can provide any additional API parameters they wish via the
`extra.params` argument. These parameters are passed directly to the OTP
API without checks.

**otpr** currently supports the following OTP API resources:

-   PlannerResource - retrieve one or more trip itineraries between
    supplied origin and destination by the designated mode(s).
-   LIsochrone Resource (OTPv1 only) - generate isochrone maps (the area
    accessible from or to a point within specified time thresholds).
-   SurfaceResource (OTPv1 only) - create and evaluate travel time
    surfaces (extremely efficient one-to-many analysis and generation of
    accessibility measures)

This package will be useful to researchers and transport planners who
want to use OTP to generate trip data for accessibility analysis or to
derive variables for use in transportation models.

Version support
---------------

**otpr** fully supports OTP versions 1 and 2. Please note the following
:

-   There is a bug in OTPv2 which means that the first returned
    itinerary for TRANSIT trips is a (usually) sub-optimal WALK-only
    option. See:
    <https://github.com/opentripplanner/OpenTripPlanner/issues/3289>.
    Workaround: set an appropriate maxWalkDistance (but see below).  
-   In OTPv2 the `maxWalkDistance` parameter is treated as a hard limit
    when the mode is either WALK or (strangely) BICYCLE. This could
    result in no itinerary being returned as the default is 800m. This
    is different from the behaviour of OTPv1 where this parameter is
    effectively ignored when the mode is WALK and not applied at all to
    BICYCLE trips. Workaround: provide a large value to this parameter
    for these modes. See:
    <http://docs.opentripplanner.org/en/latest/OTP2-MigrationGuide/#rest-api>
    for more information.

Installation
------------

``` r
# Install from CRAN
install.packages("otpr")
```

### Development version

To get a bug fix, or use a feature from the development version, you can
install otpr from GitHub. See
[NEWS](https://github.com/marcusyoung/otpr/blob/master/NEWS.md) for
changes since last release.

``` r
install.packages("devtools")
devtools::install_github("marcusyoung/otpr")
```

Getting started
---------------

``` r
library(otpr)
```

### Defining an OTP connection

The first step is to call `otp_connect()`, which defines the parameters
needed to connect to a router on a running OTP instance. The function
can also confirm that the router is reachable.

``` r
# For a basic instance of OTP running on localhost with standard ports and a 'default' router
# this is all that's needed
otpcon <- otp_connect()
#> http://localhost:8080/otp is running OTPv1
#> Router http://localhost:8080/otp/routers/default exists
```

#### Handling Time Zones

If the time zone of an OTP graph *differs* from the time zone of the
local system running **otpr** then by default returned trip start and
end times will be expressed in the local system’s time zone and not the
time zone of the graph. This is because the OTP API returns EPOCH values
and the conversion to date and time format occurs on the local system. A
‘timeZone’ column is included in returned dataframes that contain start
and end times to make this explicit. If you wish to have start and end
times expressed in the time zone of the graph, the `tz` argument can be
specified when calling the `otp_connect()` function. This must be a
valid time zone (checked against the vector returned by `OlsonNames()`);
for example: “Europe/Berlin”.

Querying the OTP API
--------------------

### Function behaviour

The functions that query the OTP API return a list of three or more
elements. The first element is an errorId - with the value “OK” or the
error code returned by OTP. If errorId is “OK”, the second element will
contain the query response; otherwise it will contain the OTP error
message. There may be further list elements forming the query response.
The last element will be the query URL that was submitted to the OTP API
(for information and useful for troubleshooting).

### Distance between two points

To get the trip distance in metres between an origin and destination on
the street and/or path network use `otp_get_distance()`. You can specify
the required mode: CAR (default), BICYCLE or WALK are valid. The trip
information will relate to the *first* itinerary that was returned by
the OTP server.

``` r
# Distance between Manchester city centre and Manchester airport by CAR
otp_get_distance(
  otpcon,
  fromPlace = c(53.48805,-2.24258),
  toPlace = c(53.36484,-2.27108)
)
#> $errorId
#> [1] "OK"
#> 
#> $distance
#> [1] 29051.51
#> 
#> $query
#> [1] "http://localhost:8080/otp/routers/default/plan?fromPlace=53.48805,-2.24258&toPlace=53.36484,-2.27108&mode=CAR"

# Now for BICYCLE
otp_get_distance(
  otpcon,
  fromPlace = c(53.48805,-2.24258),
  toPlace = c(53.36484,-2.27108),
  mode = "BICYCLE"
)
#> $errorId
#> [1] "OK"
#> 
#> $distance
#> [1] 16065.04
#> 
#> $query
#> [1] "http://localhost:8080/otp/routers/default/plan?fromPlace=53.48805,-2.24258&toPlace=53.36484,-2.27108&mode=BICYCLE"
```

### Time between two points

To get the trip duration in minutes between an origin and destination
use `otp_get_times()`. You can specify the required mode: TRANSIT (all
available transit modes), BUS, RAIL, SUBWAY, TRAM, CAR, BICYCLE, and
WALK are valid. All the public transit modes automatically allow WALK.
There is also the option to combine TRANSIT with BICYCLE.

``` r
# Time between Manchester city centre and Manchester airport by BICYCLE
otp_get_times(
  otpcon,
  fromPlace = c(53.48805,-2.24258),
  toPlace = c(53.36484,-2.27108),
  mode = "BICYCLE"
)
#> $errorId
#> [1] "OK"
#> 
#> $duration
#> [1] 60.12
#> 
#> $query
#> [1] "http://localhost:8080/otp/routers/default/plan?fromPlace=53.48805,-2.24258&toPlace=53.36484,-2.27108&mode=BICYCLE&date=12-21-2020&time=23:57:43&maxWalkDistance=800&walkReluctance=2&waitReluctance=1&arriveBy=FALSE&transferPenalty=0&minTransferTime=0"


# By default the date and time of travel is taken as the current system date and
# time. This can be changed using the 'date' and 'time' arguments
otp_get_times(
  otpcon,
  fromPlace = c(53.48805,-2.24258),
  toPlace = c(53.36484,-2.27108),
  mode = "TRANSIT",
  date = "04-29-2020",
  time = "07:15:00"
)
#> $errorId
#> [1] "OK"
#> 
#> $duration
#> [1] 42.2
#> 
#> $query
#> [1] "http://localhost:8080/otp/routers/default/plan?fromPlace=53.48805,-2.24258&toPlace=53.36484,-2.27108&mode=TRANSIT,WALK&date=04-29-2020&time=07:15:00&maxWalkDistance=800&walkReluctance=2&waitReluctance=1&arriveBy=FALSE&transferPenalty=0&minTransferTime=0"
```

### Breakdown of time by mode, waiting time and transfers

To get more information about the trip when using transit modes,
`otp_get_times()` can be called with the `detail` argument set to TRUE.
The trip duration (minutes) is then further broken down by time on
transit, walking time (from/to and between stops), waiting time (when
changing transit vehicle or mode), and number of transfers (when
changing transit vehicle or mode). By default the function returns trip
information for the first itinerary suggested by the OTP server.
However, additional itineraries can be requested by specifying the
`maxItineraries` argument. The function will return every available
itinerary suggested by the OTP server, in order, *up to* the value of
`maxItineraries` (the default is 1).

``` r
# Time between Manchester city centre and Manchester airport by TRANSIT with detail
otp_get_times(
  otpcon,
  fromPlace = c(53.48805,-2.24258),
  toPlace = c(53.36484,-2.27108),
  mode = "TRANSIT",
  date = "04-29-2020",
  time = "07:15:00",
  detail = TRUE,
  maxItineraries = 1
)
#> $errorId
#> [1] "OK"
#> 
#> $itineraries
#>                 start                 end      timeZone duration walkTime
#> 1 2020-04-29 07:37:31 2020-04-29 08:19:43 Europe/London     42.2     5.17
#>   transitTime waitingTime transfers
#> 1          37        0.03         0
#> 
#> $query
#> [1] "http://localhost:8080/otp/routers/default/plan?fromPlace=53.48805,-2.24258&toPlace=53.36484,-2.27108&mode=TRANSIT,WALK&date=04-29-2020&time=07:15:00&maxWalkDistance=800&walkReluctance=2&waitReluctance=1&arriveBy=FALSE&transferPenalty=0&minTransferTime=0"
```

#### Details of each leg for transit-based trips

To get information about each leg of transit-based trips,
`otp_get_times()` can be called with both the `detail` and `includeLegs`
arguments set to TRUE. A column called ‘legs’ will then be included in
the itineraries dataframe. This column contains a nested ‘legs’
dataframe for each itinerary. The ‘legs’ dataframe contains a row for
each leg of the trip. The information provided for each leg includes
start and end times, duration, distance, mode, route details, agency
details, and stop names. There is also a column called ‘departureWait’
which is the length of time in minutes required to wait before the start
of a leg. The sum of ‘departureWait’ will equal the total waiting time
for the itinerary.

``` r
# Time between Manchester city centre and Manchester airport by TRANSIT with detail and legs
trip <- otp_get_times(
  otpcon,
  fromPlace = c(53.48805,-2.24258),
  toPlace = c(53.36484,-2.27108),
  mode = "TRANSIT",
  date = "04-29-2020",
  time = "07:15:00",
  detail = TRUE,
  includeLegs = TRUE,
  maxItineraries = 2
)

# Legs for the first itinerary returned by OTP (first 9 columns)
trip$itineraries$legs[[1]][1:9]
#>             startTime             endTime      timeZone mode departureWait
#> 1 2020-04-29 07:37:31 2020-04-29 07:38:59 Europe/London WALK          0.00
#> 2 2020-04-29 07:39:00 2020-04-29 08:16:00 Europe/London RAIL          0.02
#> 3 2020-04-29 08:16:01 2020-04-29 08:19:43 Europe/London WALK          0.02
#>   duration  distance routeType routeId
#> 1     1.47    98.057        NA    <NA>
#> 2    37.00 17872.820         2 1:13081
#> 3     3.70   245.949        NA    <NA>
```

### Travel time isochrones (OTPv1 only)

The `otp_get_isochrone()` function can be used to get one or more travel
time isochrones in either GeoJSON or SF format. These are only available
for transit or walking modes (OTP limitation). They can be generated
either *from* (default) or *to* the specified location.

#### GeoJSON example

``` r
# 900, 1800 and 2700 second isochrones for travel *to* Manchester Airport by any transit mode
my_isochrone <- otp_get_isochrone(
  otpcon,
  location = c(53.36484, -2.27108),
  fromLocation = FALSE,
  cutoffs = c(900, 1800, 2700),
  mode = "TRANSIT",
  date = "04-29-2020",
  time = "07:15:00"
)

# function returns a list of two elements
names(my_isochrone)
#> [1] "errorId"  "response" "query"

# now write the GeoJSON (in the "response" element) to a file so it can be opened in QGIS (for example)
write(my_isochrone$response, file = "my_isochrone.geojson")
```

#### SF example

``` r
# request format as "SF"
my_isochrone <- otp_get_isochrone(
  otpcon,
  location = c(53.36484, -2.27108),
  format = "SF",
  fromLocation = FALSE,
  cutoffs = c(900, 1800, 2700, 3600, 4500, 5400),
  mode = "TRANSIT",
  date = "04-29-2020",
  time= "07:15:00",
  maxWalkDistance = 1600,
  walkReluctance = 5,
  minTransferTime = 600
)

# plot using tmap package

library(tmap)
library(tmaptools)

# set bounding box
bbox <- bb(my_isochrone$response)
# get OSM tiles
osm_man <- read_osm(bbox, ext = 1.1)
# plot isochrones
tm_shape(osm_man) +
  tm_rgb() +
  tm_shape(my_isochrone$response) +
  tm_fill(
    col = "time",
    alpha = 0.8,
    palette = "-plasma",
    n = 6,
    style = "cat",
    title = "Time (seconds)"
  ) + tm_layout(legend.position = c("left", "top"), legend.bg.color = "white", 
                main.title = "15-90 minute isochrone to Manchester Airport", 
                main.title.size = 0.8)
```

<img src="man/figures/unnamed-chunk-9-1.png" width="80%" />

### One-to-many Travel Time Analysis (OTPv1 only)

If you wish to calculate the travel time from one or more origins to
many destinations, querying the OTP journey planning API (using
`otp_get_times()`) may not be the best option as it requires multiple
requests to the API which can be very inefficient. An alternative is to
use the OTP surface analysis feature, which enables you to calculate the
travel time from an origin to thousands of destinations in about the
same time it takes to perform a single origin:destination lookup. This
is achieved by generating a surface for an origin which contains the
travel time to every geographic coordinate that can be reached from that
origin by the specified transport mode.

Once the surface has been generated, it can be evaluated to rapidly
retrieve the travel times from the origin to each ‘destination’ point
provided in a supplied CSV file. This file, known as a pointset, can
also contain the quantities of one or more ‘opportunities’ that are
associated with each point. During evaluation, OTP will sum the
opportunities available at each additional minute of travel time, and
**otpr** generates a cumulative sum of the opportunities. For example,
you might have a poinset of workplace zones and a column with the number
of jobs within each zone. The output will be a cumulative sum of jobs
reachable for each minute of travel time by the mode specified when the
surface was generated.

Before a surface analysis can be performed, OTP must be started with the
`--analyst` switch. To evaluate one or more pointsets against a surface,
the location of the pointset CSV file(s) must be specified using the
`--pointSets` switch followed by the file path. For more information
about the required file format for a pointset CSV file and the switches
to start OTP with, see:
<http://docs.opentripplanner.org/en/dev-1.x/Surface/>.

#### Create a surface

Once an OTP instance has been started in analysis mode, a surface can be
generated by calling the `otp-create-surface()` function. The arguments
that can be passed to this function are very similar to
`otp_get_times()`. The main differences are the exclusion of the
`toPlace` argument and two new function-specific arguments - `getRaster`
and `rasterPath`. These are used to request a raster image (a geoTIFF
file) of the generated surface which is saved to the local file system.
If the surface is successfully generated, the function will return the
OTP ID number of the surface - this will be needed for any subsequent
evaluation against the surface.

There are a few things to note regarding the raster image that OTP
creates:

-   The travel time cutoff for a surface appears to be 120 minutes.
    Every grid cell within the extent of the graph that is 120 minutes
    travel time or beyond, *or not accessible at all*, is given the
    value of 120.
-   Any grid cell outside of the extent of the network (i.e. no-data
    cells) is given given the value 128.
-   It is advisable to interpret the raster of a surface in conjunction
    with results from evaluating the surface (see below).
-   OTP can take a while the first time a raster of a surface is
    generated after starting up. Subsequent rasters (even for different
    origins) are much faster to generate.

``` r
# create surface with origin as Manchester city centre
otp_create_surface(otpcon, fromPlace = c(53.479167,-2.244167), date = "03-26-2020",
time = "08:00:00", mode = "TRANSIT", maxWalkDistance = 1600, getRaster = TRUE,
rasterPath = "C:/temp")
#> $errorId
#> [1] "OK"
#> 
#> $surfaceId
#> [1] 7
#> 
#> $surfaceRecord
#> [1] "{\"id\":7,\"params\":{\"mode\":\"TRANSIT,WALK\",\"date\":\"03-26-2020\",\"walkReluctance\":\"2\",\"arriveBy\":\"FALSE\",\"minTransferTime\":\"0\",\"fromPlace\":\"53.479167,-2.244167\",\"batch\":\"TRUE\",\"transferPenalty\":\"0\",\"time\":\"08:00:00\",\"maxWalkDistance\":\"1600\",\"waitReluctance\":\"1\"}}"
#> 
#> $rasterDownload
#> [1] "C:/temp/surface_7.tiff"
#> 
#> $query
#> [1] "http://localhost:8080/otp/surfaces?fromPlace=53.479167,-2.244167&mode=TRANSIT,WALK&date=03-26-2020&time=08:00:00&maxWalkDistance=1600&walkReluctance=2&waitReluctance=1&transferPenalty=0&minTransferTime=0&arriveBy=FALSE&batch=TRUE"
```

![Example of surface raster visualised in
QGIS](man/figures/surface0.jpg)

#### Evaluate a surface

Once a surface has been generated, it can be evaluated using the
`otp_evaluate_surface()` function. The ID of the surface (returned by
the `otp_create_surface()` function) and the name of a pointset (which
is the pointset file name excluding the extension) must be provided as
arguments. The function will return one or more dataframes for each of
the ‘opportunity’ columns in the pointset CSV file. Each of these
dataframes contains four columns:

-   minutes: the time from the surface origin in one-minute increments.
-   counts: the number of opportunity locations reached within each
    minute interval.
-   sum: the sum of the opportunities at each of the locations reached
    within each minute interval.
-   cumsums: a cumulative sum of the opportunities reached.

As noted above, there is a cutoff of 120 minutes for the surface and
only data for minutes *up to* 120 are returned by OTP. Further
investigation into how and where this is controlled is ongoing.

If the optional `detail` argument is set to TRUE, then a dataframe
called ‘times’ containing the time taken (in seconds) to reach each
point in the pointset file will also be returned. If a point is not
reachable the time will be recorded as NA. This could mean that the
point is genuinely unreachable by the mode (e.g. if it is CAR mode and
the location is only accessible by walking or cycling) or that point
falls outside of the surface (which might be due to the extent of the
network or the 120 minute limit to the surface extent). The ‘times’
table can be joined with the data from the original pointset file to get
the travel time from the origin to each destination.

``` r
response <- otp_evaluate_surface(otpcon, surfaceId = 0, pointset = "jobs", detail = TRUE)
# Look at first few rows of the job opportunity data
head(response$jobs)
#>   minutes counts sums cumsums
#> 1       1      0  230     230
#> 2       2      0  442     672
#> 3       3      1  636    1308
#> 4       4      3 1689    2997
#> 5       5      4 2872    5869
#> 6       6      8 4300   10169
# And the last few rows
tail(response$jobs)
#>     minutes counts sums cumsums
#> 115     115      3 2057 1154742
#> 116     116      3 1349 1156091
#> 117     117      2  974 1157065
#> 118     118      2  793 1157858
#> 119     119      0  284 1158142
#> 120     120      1   92 1158234
# Number of job opportunities accesible with 60 minutes from origin by TRANSIT
response$jobs$cumsums[60]
#> [1] 706590
# And a peak at the times dataframe
head(response$times)
#>   point time
#> 1     1 6736
#> 2     2 2966
#> 3     3  328
#> 4     4 2894
#> 5     5 4199
#> 6     6   NA
```

Learning more
-------------

The example function calls shown above can be extended by passing
additional parameters to the OTP API. This includes the advanced option
to pass any parameter that is not an **otpr** argument directly to the
OTP API via the `extra.params` argument. Further information is
available in the documentation for each function:

``` r
# get help on using the otp_get_times() function
?otp_get_times
```

If you are new to OTP, then the best place to start is to work through
the tutorial, [OpenTripPlanner Tutorial - creating and querying your own
multi-modal route planner](https://github.com/marcusyoung/otp-tutorial).
This includes everything you need, including example data, to get
started with OTPv1. The tutorial also has examples of using **otpr**
functions, and helps you get the most from the package, for example
using it to populate an origin-destination matrix.

For more guidance on how **otpr**, in conjunction with OTP, can be used
to generate data for input into models, you may be interested in: [An
automated framework to derive model variables from open transport data
using R, PostgreSQL and
OpenTripPlanner](https://eprints.soton.ac.uk/389728/).

Getting help
------------

-   Please [report any issues or
    bugs](https://github.com/marcusyoung/otpr/issues).

How to cite
-----------

Please cite **otpr** if you use it. Get citation information using:
`citation(package = 'otpr')`:

``` r
citation(package = 'otpr')
#> 
#> To cite the otpr package in publications, please use the following. You
#> can obtain the DOI for a specific version from:
#> https://zenodo.org/record/4065250
#> 
#>   Marcus Young (2020). otpr: An API wrapper for OpenTripPlanner. R
#>   package version 0.4.2. https://doi.org/10.5281/zenodo.4065250
#> 
#> A BibTeX entry for LaTeX users is
#> 
#>   @Manual{,
#>     author = {{Marcus Young}},
#>     title = {{otpr: An API wrapper for OpenTripPlanner}},
#>     year = {2020},
#>     note = {{R package version 0.4.2}},
#>     doi = {{10.5281/zenodo.4065250}},
#>   }
```

Want to say thanks?
-------------------

<a href="https://ko-fi.com/marcusyoung"><img src='man/figures/BuyMeACoffee_blue@2x.png' align="left" width=200/></a>

</br>
