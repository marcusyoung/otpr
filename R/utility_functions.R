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
    list("TRANSIT",
         "WALK",
         "BICYCLE",
         "CAR",
         "BUS",
         "RAIL",
         c("TRANSIT", "BICYCLE"))
  
  if (!(Position(function(x)
    identical(x, mode), valid_mode, nomatch = 0) > 0)) {
    stop(
      paste0(
        "Mode must be one of: 'TRANSIT', 'WALK', 'BICYCLE', 'CAR', 'BUS', 'RAIL', or 'c('TRANSIT', 'BICYCLE')', but is '",
        paste(mode, collapse = ', '),
        "'."
      )
    )
  } else {
    # add WALK to relevant modes - as mode may be a vector of length > 1 use identical
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

#' Check OTP parameters
#' 
#' @param otpcon Object of otpcon class
#' @keywords internal
#' @importFrom utils hasName
otp_check_params <- function (otpcon, ...)
{
  call <- sys.call()
  call[[1]] <- as.name('list')
  args <- eval.parent(call)
  print(args)
  
  coll <- checkmate::makeAssertCollection()
  
  # all functions must provide otpcon.
  
  checkmate::assert_class(otpcon, "otpconnect", add = coll)
  
  
  if (hasName(args, "fromPlace")) {
    checkmate::assert_numeric(
      args[["fromPlace"]],
      lower =  -180,
      upper = 180,
      len = 2,
      add = coll
    )
  }
  
  if (hasName(args, "toPlace")) {
    checkmate::assert_numeric(
      args[["toPlace"]],
      lower =  -180,
      upper = 180,
      len = 2,
      add = coll
    )
  }
  
  if (hasName(args, "maxWalkDistance")) {
    checkmate::assert_number(args[["maxWalkDistance"]], lower = 0, add = coll)
  }
  
  if (hasName(args, "arriveBy")) {
    checkmate::assert_logical(args[["arriveBy"]], add = coll)
  }
  
  
  if (hasName(args, "walkReluctance")) {
    checkmate::assert_number(args[["walkReluctance"]], lower = 0, add = coll)
  }
  
  if (hasName(args, "waitReluctance")) {
    if (isFALSE(checkmate::testNumber(
      args[["waitReluctance"]],
      lower = 1,
      upper = ifelse(hasName(args, "walkReluctance"), args[["walkReluctance"]], 2)
    ))) {
      coll$push(
        "waitReluctance should be greater than 1 and less than walkReluctance (default = 2). See OTP API PlannerResource documentation"
      )
    }
  }
  
  if (hasName(args, "transferPenalty")) {
    checkmate::assert_integerish(args[["transferPenalty"]], lower = 0, add = coll)
  }
  
  if (hasName(args, "minTransferTime")) {
    checkmate::assert_integerish(args[["minTransferTime"]], lower = 0, add = coll)
  }
  
  if (hasName(args, "cutoffs")) {
    checkmate::assert_integerish(args[["cutoffs"]], lower = 0, add = coll)
  }
  
  if (hasName(args, "batch")) {
    checkmate::assert_logical(args[["batch"]], add = coll)
  }
  
  checkmate::reportAssertions(coll)
  
  # check date and time are valid
  
  if (hasName(args, "date")) {
    if (otp_is_date(args[["date"]]) == FALSE) {
      stop("date must be in the format mm-dd-yyyy")
    }
  }
  
  if (hasName(args, "time")) {
    if (otp_is_time(args[["time"]]) == FALSE) {
      stop("time must be in the format hh:mm:ss")
    }
  }
  
}
