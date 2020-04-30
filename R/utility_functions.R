#' Checks the date format
#'
#' @param date the supplied date.
#' @keywords internal
otp_is_date <- function(date) {
  tryCatch(!is.na(as.Date(date, "%m-%d-%Y")),
           error = function(err) {FALSE})
}

#' Checks the time format
#'
#' @param time the supplied time.
#' @keywords internal
otp_is_time <- function(time) {
  tryCatch(!is.na(as.POSIXlt(paste("2019-03-25", time), format="%Y-%m-%d %H:%M:%S")),
           error = function(err) {FALSE})
}

#' Checks if two vectors are the same but where order doesn't matter
#' @param a vector, to be matched
#' @param b vector, to be matched
#' @keywords internal
otp_vector_match <- function(a, b)  {
  return(identical(sort(a), sort(b)))
}

#' Convert time from EPOCH format
#' @param epoch, time since EPOCH (milliseconds)
#' @param tz, timezone (string)
#' @keywords internal
otp_from_epoch <- function(epoch, tz) {
  return(as.POSIXct(epoch / 1000, origin = "1970-01-01", tz = tz))
}


