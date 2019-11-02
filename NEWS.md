# otpr 0.2.0.9000

## New features

* Added support for time zones (#7). The OTP API returns itinerary start and end
times as EPOCH values. otpr converts these to hh:mm:ss format using the `as.POSIXct()`
function. Previously, a time zone argument was not provided to this function. As a
result `as.POSIXct()` assumed the time zone to be the current time zone of the local
system. When the local system time zone is the same as the time zone of the
router's graph then there will be no confusion. However, if the time zone of the
graph is different from the time zone of the local system then the start and end
times will be expressed in the local system time zone and not the time zone of the
graph. To adddress this the following changes have been made:
    * Added a `tz` argument to the `otp_connect()` function. By default this
is set to the local system's time zone. If the router's graph is in a different
time zone the user can specify it (for example, "Europe/Berlin").
    * The dataframe returned by `otp_get_times()` when the `detail` argument is set to
TRUE now includes an additional 'time zone' column. This shows the time zone of 
the returned itinerary start and end times. This makes explit what time zone
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
