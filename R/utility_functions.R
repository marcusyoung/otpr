#' Checks the date format
#'
#' @param date the supplied date.
#' @keywords internal
otp_is_date <- function(date) {
  tryCatch(
    !is.na(as.Date(date, "%m-%d-%Y")),
    error = function(err) {
      FALSE
    }
  )
}

#' Checks the time format
#'
#' @param time the supplied time.
#' @keywords internal
otp_is_time <- function(time) {
  tryCatch(
    !is.na(as.POSIXlt(paste(
      "2019-03-25", time
    ), format = "%Y-%m-%d %H:%M:%S")),
    error = function(err) {
      FALSE
    }
  )
}

#' Checks if two vectors are the same but where order doesn't matter
#'
#' @param a vector, to be matched
#' @param b vector, to be matched
#' @keywords internal
otp_vector_match <- function(a, b)  {
  return(identical(sort(a), sort(b)))
}

#' Convert time from EPOCH format
#'
#' @param epoch, time since EPOCH (milliseconds)
#' @param tz, timezone (string)
#' @keywords internal
otp_from_epoch <- function(epoch, tz) {
  return(as.POSIXct(epoch / 1000, origin = "1970-01-01", tz = tz))
}

#' Check and process transport mode
#'
#' @param mode, character vector
#' @keywords internal
otp_check_mode <- function(mode) {
  mode <- toupper(mode)
  valid_mode <-
    list(
      "TRANSIT",
      "WALK",
      "BICYCLE",
      "CAR",
      "BUS",
      "RAIL",
      "TRAM",
      "SUBWAY",
      c("TRANSIT", "BICYCLE")
    )
  
  if (!(Position(function(x)
    identical(x, mode), valid_mode, nomatch = 0) > 0)) {
    stop(
      paste0(
        "Mode must be one of: 'TRANSIT', 'WALK', 'BICYCLE', 'CAR', 'BUS', 'TRAM', 'SUBWAY, 'RAIL', or 'c('TRANSIT', 'BICYCLE')', but is '",
        paste(mode, collapse = ', '),
        "'."
      )
    )
  } else {
    # Need to add WALK to relevant modes - as mode may be a vector of length > 1 use identical
    # otpr_vectorMatch is TRUE if mode is c("TRANSIT", "BICYCLE") or c("BICYCLE", "TRANSIT")
    if (identical(mode, "TRANSIT") |
        identical(mode, "BUS") |
        identical(mode, "RAIL") |
        otp_vector_match(mode, c("TRANSIT", "BICYCLE"))) {
      mode <- append(mode, "WALK")
    }
    return(paste(mode, collapse = ","))
  }
}