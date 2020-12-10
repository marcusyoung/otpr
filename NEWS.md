# otpr 0.4.2.9000 (Development version)

## New Features

* Support for creating and evaluating surfaces. The OTP surfaces endpoint enables
efficient running of one-to-many queries. Once a surface for an origin has been
generated (a surface is specific to a transport mode, date, time etc), distances
from that origin to a set of locations (or 'opportunities') can be generated very
quickly - many thousands in a few seconds. In addition, one or more indicators of
accessibility for those opportunities can be generated at the same time. For example,
if the opportunity was census workplace zones, a count of the number of zones and the
number of jobs accessible from the origin at one-minute intervals are returned, along
with a cumulative sum, enabling a rapid assessment of the number of job opportunities
within, say, 30 minutes. There are two new functions to support surfaces:
    * `otp_create_surface()` creates a surface stored in memory on the OTP server and
    returns its Id number. It can optionally also retrieve and save a raster (geo TIFF)
    of the surface for visualisation in R (or other GIS).
    * `otp_evaluate_surface()` uses an existing surface and a pointset (loaded from a CSV file
    provided to OTP at server startup) to calculate the travel time to each point location
    in the pointset file and to generate accessibility indicators for one or more 'opportunity'
    columns. A list is returned containing a dataframe for each 'opportunity' and, optionally,
    a dataframe of the time taken to travel from the surface's origin to each location point.
    This function can also be used to retrieve the time from an origin to many destinations.


# otpr 0.4.2

## New Features

* `otp_get_distance()`, `otp_get_times()` and `otp_get_isochrone()` now also
return the query URL that was submitted to the OTP API. This is for user reference
and can be useful for troubleshooting.

* Now also imports **urltools**, used to return decoded query URL.

## Other

* Test coverage greatly extended.

# otpr 0.4.1

## Behaviour change

* `otp_get_times()` now returns a legs datafame, when requested, for WALK, BICYCLE 
and CAR modes. For these modes this will contain a single leg. This is for consistency
with other modes.

## Bug fixes

* Since 0.4.0 some parameters (`walkReluctance`, `arriveBy`, `transferPenalty` 
and `minTransferTime`) were not being passed to the OTP API by the
`otp_get_times()` function. This has been fixed.

* There were instances when `otp_get_times()` would generate an error when journey legs
were requested. This was due to an expected attribute in the OTP API response not 
being present. There is some inconsistency in the columns that are returned by OTP
for the legs, dependent on the mode, and what values appear in the original GTFS feeds.
Rather than limit the leg detail to the smaller subset of columns that are guaranteed
to be present, the function now includes columns in the `legs` dataframe for the attributes
that are present (as well as additional **otpr** calculated columns). This could mean some
inconsistency in the columns returned in the `legs` dataframe between queries.
If you make use of these extra columns in post-processing then you may need additional
code to check for column existence.

# otpr 0.4.0

## Experimental feature

* Support for OTP version 2 (experimental). As OTPv2 has not yet been released
changes to its codebase could cause errors in **otpr** or unexpected behaviour
when used against an OTPv2 instance. This version was tested against commit [cce4e7ea](https://github.com/opentripplanner/OpenTripPlanner/commit/cce4e7ea157948156a67c0552d1a9228c8844b00).
Please report any problems in [Issues](https://github.com/marcusyoung/otpr/issues).
Current known issues:
    * `otp_get_isochrone()` is only supported in OTPv1 as this feature has been removed
    from OTPv2.
    * The `maxWalkDistance` parameter used in the `otp_get_times()` function is treated
    as a hard limit when the mode is either WALK or BICYCLE. This could result in no itinerary being
    returned as the default is 800m. This is different from the behaviour of OTPv1
    where this parameter is effectively ignored when the mode is WALK and not applied at all
    to BICYCLE trips. Workaround: provide a large value to this parameter for these modes.
    * The 'routeType' and 'agencyUrl' columns do not appear in the data frame of
    journey legs as these are not returned by OTPv2. 

## Deprecated arguments

* `otp_connect()` no longer uses the optional `check` argument. The function
will now always check that the OTP server and specified router are reachable. This
is because the version of OTP must now be retrieved from the `../otp` endpoint
so that **otpr** can support OTP versions 1 and 2.

## Other

* Compatibility with R 4.0.0. Note: R 4.0.0 requires reinstallation of all packages
on your system. In particular, make sure that you have re-installed **curl**, 
as `otp_connect()` can appear to fail without the reason - that **curl** has not been
installed after 4.0.0 - being explicitly reported. 
* `otp_connect()` now retrieves the version of the OTP server. This is contained
in the otpconnect object that is returned and reported to the user. Note that OTPv2
does not support named or multiple routers.
* Now also imports the **sf** package. The `st_make_valid()` function is used 
in `otp_get_isochrone()` to correct any geometry errors in the sf object before 
it is returned to the user. OTP appears to return polygons that fail validation
by `st_is_valid` from the **sf** package.

# otpr 0.3.0

## New features

* Added option to request information about each of the legs in a returned 
transit itinerary. There is a new parameter available for `otp_get_times()` called 
`includeLegs`. If this is set to TRUE (default is FALSE) and `detail` is also set
to TRUE and `mode` includes a transit mode, then the list returned by the
function will contain a third element: a dataframe called `legs`. This consists
of a row for each leg of the trip. Information provided includes `departureWait`
which is the length of time in minutes required to wait for the start of a leg.

* Added support for time zones (#7). The OTP API returns itinerary start and end
times as EPOCH values. otpr converts these to hh:mm:ss format using the `as.POSIXct()`
function. Previously, a time zone argument was not provided to this function. As a
result `as.POSIXct()` assumed the time zone to be the current time zone of the local
system. When the local system time zone is the same as the time zone of the
router's graph then there will be no confusion. However, if the time zone of the
graph is different from the time zone of the local system then the start and end
times will be expressed in the local system time zone and not the time zone of the
graph. To address this the following changes have been made:
    * Added a `tz` argument to the `otp_connect()` function. By default this
is set to the local system's time zone. If the router's graph is in a different
time zone the user can specify it (for example, "Europe/Berlin").
    * The dataframe returned by `otp_get_times()` when the `detail` argument is set to
TRUE now includes an additional 'time zone' column. This shows the time zone of 
the returned itinerary start and end times. This makes explicit what time zone
these times are expressed in.


# otpr 0.2.0

## New features
* Added option to `otp_get_isochrone()` to return isochrone as either GeoJSON (default)
or as a simple feature collection (**sf**). Specified using the new `format` argument (#4)

* Now also imports **geojsonsf**, used in `otp_get_isochrone()`

## Bug fixes
* The unit of time returned by `otp_get_times()` was inconsistent. When the 'detail'
parameter was set to TRUE the time was returned in seconds; otherwise the time was
returned in minutes. This has been corrected so that time is always returned in
minutes (#3).

* Remove 'curl' from 'Imports:' to fix CRAN binary build error on some platforms (#2)

# otpr 0.1.0

Initial release.
