#' Checks the date format
#'
#' @param date the supplied date.
otpr_isDate <- function(date) {
  tryCatch(!is.na(as.Date(date, "%m-%d-%Y")),
           error = function(err) {FALSE})
}

#' Checks the time format
#'
#' @param time the supplied time.
otpr_isTime <- function(time) {
  tryCatch(!is.na(as.POSIXlt(paste("2019-03-25", time), format="%Y-%m-%d %H:%M:%S")),
           error = function(err) {FALSE})
}

#' Checks if two vectors are the same but where order doesn't matter
#' @param a vector, to be matched
#' @param b vector, to be matched
otpr_vectorMatch <- function(a, b)  {
  return(identical(sort(a), sort(b)))
}


