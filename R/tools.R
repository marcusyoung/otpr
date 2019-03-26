#' Checks the date format
#'
#' @param date the supplied date.
IsDate <- function(date) {
  tryCatch(!is.na(as.Date(date, "%m-%d-%Y")),
           error = function(err) {FALSE})
}


#' Checks the time format
#'
#' @param time the supplied time.
IsTime <- function(time) {
  tryCatch(!is.na(as.POSIXlt(paste("2019-03-25", time), format="%Y-%m-%d %H:%M:%S")),
           error = function(err) {FALSE})
}

