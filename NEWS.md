# otpr 0.2.0.9000

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
