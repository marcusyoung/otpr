# otpr 0.1.0.9000

## New features
* Added option to `otp_get_isochrone()` to return isochrone as either GeoJSON (default)
or as a simple feature collection (**sf**). Specified using the new `format` argument (#4)

* Now also imports **geojsonsf**, used in `otp_get_isochrone()`

## Bug fixes
* Remove 'curl' from 'Imports:' to fix CRAN binary build error on some platforms (#2)

# otpr 0.1.0

Initial release.
