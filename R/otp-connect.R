#' Set up and confirm a connection to an OTP instance.
#'
#' Defines the parameters required to connect to a router on an OTP instance and,
#' if required, confirms that the instance and router are queryable.
#'
#' @param hostname A string, e.g. "ec2-34-217-73-26.us-west-2.compute.amazonaws.com".
#'     Optional, default is "localhost".
#' @param router A string, e.g. "UK2018". Optional, default is "default". Do not
#' specify for OTPv2 which does not support named routers.
#' @param port A positive integer. Optional, default is 8080.
#' @param ssl Logical, indicates whether to use https. Optional, default is FALSE.
#' @param tz A string, containing the time zone of the router's graph. Optional.
#' This should be a valid time zone (checked against vector returned by
#' `OlsonNames()`). For example: "Europe/Berlin". Default is the timezone of the
#' current system (obtained from \code{Sys.timezone()}). Using the default will
#' be ok if the current system time zone is the same as the time zone of the OTP
#' graph.
#' @param check Deprecated and has no effect.
#' @return Returns S3 object of class otpconnect if reachable.
#' @examples \dontrun{
#' otpcon <- otpr_connect()
#' otpcon <- otpr_connect(router = "UK2018",
#'                       ssl = TRUE)
#' otpcon <- otpr_connect(hostname = "ec2.us-west-2.compute.amazonaws.com",
#'                       router = "UK2018",
#'                       port = 8888,
#'                       ssl = TRUE)
#'}
#' @export
otp_connect <- function(hostname = "localhost",
                        router = "default",
                        port = 8080,
                        tz = Sys.timezone(),
                        ssl = FALSE,
                        check = TRUE)
{

  # the check argument is now deprecated and has no effect
  if (!missing("check"))
    warning("argument 'check' has been deprecated and has no effect", call. = FALSE)

  # argument checks

  coll <- checkmate::makeAssertCollection()
  checkmate::assert_string(hostname, add = coll)
  checkmate::assert_string(router, add = coll)
  checkmate::assert_int(port, lower = 1, add = coll)
  checkmate::assert_logical(ssl, add = coll)
  checkmate::reportAssertions(coll)

  # Check if tz is a valid timezone
  if (isFALSE(checkmate::test_choice(tz, OlsonNames()))) {
    stop("Assertion on 'tz' failed:", " Must be a valid time zone")
  }

  # Create the otpcon object
  otpcon <- list(
    hostname = hostname,
    version = 0,
    router = router,
    port = port,
    tz = tz,
    ssl = ssl
  )

  # Set the name for the class
  class(otpcon) <- append(class(otpcon), "otpconnect")

  # Get OTP version
  # /otp API endpoint must be enabled on the OTP instance (it is by default)
  req <- try(httr::GET(make_url(otpcon)$otp), silent = T)
  if (class(req) == "try-error") {
    stop("Unable to connect to OTP. Does ",
         make_url(otpcon)$otp,
         " even exist?")
  } else if (req$status_code != 200) {
    stop("Unable to determine OTP version. Does ",
         make_url(otpcon)$otp,
         " even exist?")
  } else {
    # convert to text
    req <- httr::content(req, as = "text", encoding = "UTF-8")
    # parse text to json
    req <- jsonlite::fromJSON(req, flatten = TRUE)
    # update major version in otpcon
    otpcon$version <- req$serverVersion$major
    message(make_url(otpcon)$otp, " is running OTPv", otpcon$version)
  }

  # Confirm router is queryable
  if (check_router(otpcon) == 200) {
    message("Router ", make_url(otpcon)$router, " exists")
    return(otpcon)
  } else {
    stop("Router ", make_url(otpcon)$router,  " does not exist")
  }
}


# otpconnect class method to generate router url

make_url <- function(x)
{
  UseMethod("make_url", x)
}

make_url.default <- function(x)
{
  warning(
    "make_url does not know how to handle objects of class ",
    class(x),
    ", and can only be used on the class otpconnect"
  )
  return(NULL)
}

make_url.otpconnect <- function(x)
{
  otp_url <- paste0(ifelse(isTRUE(x$ssl), 'https://', 'http://'),
                    x$hostname,
                    ':',
                    x$port,
                    '/otp')
  router_url <- paste0(otp_url,
                       '/routers/',
                       x$router)
  return(list(otp = otp_url, router = router_url))
}


# otpconnect method to check if router exists

check_router <- function(x)
{
  UseMethod("check_router", x)
}

check_router.default <- function(x)
{
  warning(
    "check_router does not know how to handle objects of class ",
    class(x),
    ", and can only be used on the class otpconnect"
  )
  return(NULL)
}

check_router.otpconnect <- function(x)
{
  check <- try(httr::GET(make_url(x)$router), silent = T)
  if (class(check) == "try-error") {
    return(check[1])
  } else{
    return(check$status_code)
  }

}
