# otpr 0.3.0.9000

## Other

* Now also imports the lwgeom package and the `st_make_valid()` function is used
in `otp_get_isochrone()` to correct any geometry errors in the sf object before 
it is returned to the user.

# otpr 0.3.0

## New features

* Added option to request information about each of the legs in a returned 
transit itinerary. There is a new parameter available for `otp_get_times()` called 
`includeLegs`. If this is set to TRUE (default is FALSE) and `detail` is also set
to TRUE and `mode` includes a transit mode, then the list returned by the
function will contain a third dataframe called `legs`. This consists of a row for
each leg of the trip. Information provided includes `departureWait` which is the
length of time in minutes required to wait for the start of a leg.

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
