#' Check OTP parameters
#'
#' @param otpcon Object of otpcon class
#' @param ... Other optional parameters
#' @keywords internal
#' @importFrom utils hasName
otp_check_params <- function (otpcon, ...)
{
  call <- sys.call()
  call[[1]] <- as.name('list')
  args <- eval.parent(call)
  
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
