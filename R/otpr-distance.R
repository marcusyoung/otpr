#' Finds the distance in metres between supplied origin and destination
#'
#' Finds the distance in metres between supplied origin and destination. Only makes
#' sense for walk, cycle or car modes (not transit)
#'
#' @param otpcon An OTP connection object produced by \code{otp_connect()}.
#' @param fromPlace Numeric vector, Latitude/Longitude pair, e.g. `c(53.48805, -2.24258)`
#' @param toPlace Numeric vector, Latitude/Longitude pair, e.g. `c(53.36484, -2.27108)`
#' @param mode Character vector, single mode of travel. Valid values are WALK, BICYCLE, or CAR. Default is CAR.

#' @return If OTP has not returned an error then a list containing \code{errorId}
#' with the value "OK" and the \code{distance} in metres. If OTP has returned an
#' error then a list containing \code{errorId} with the OTP error code and \code{errorMessage}
#' with the error message returned by OTP.
#' @export
otpr_distance <-
  function(otpcon = NULL,
           fromPlace = NULL,
           toPlace = NULL,
           mode = "CAR")
  {


    mode <- toupper(mode)


    coll <- checkmate::makeAssertCollection()
    checkmate::assert_class(otpcon, "otpconnect", add = coll)
    checkmate::assert_numeric(
      fromPlace,
      lower =  -180,
      upper = 180,
      len = 2,
      add = coll
    )
    checkmate::assert_numeric(
      toPlace,
      lower =  -180,
      upper = 180,
      len = 2,
      add = coll
    )
    checkmate::assert_choice(
      mode,
      choices = c("WALK", "BICYCLE", "CAR"),
      null.ok = F,
      add = coll
    )
    checkmate::reportAssertions(coll)

    fromPlace <- paste(fromPlace, collapse = ",")
    toPlace <- paste(toPlace, collapse = ",")
    mode <- paste(mode, collapse = ",")


    # Construct URL
    routerUrl <- make_url(otpcon)
    routerUrl <- paste0(routerUrl, "/plan")

    # Use GET from the httr package to make API call and place in req - returns json by default
    req <- httr::GET(routerUrl,
               query = list(
                 fromPlace = fromPlace,
                 toPlace = toPlace,
                 mode = mode
               ))
    # convert response content into text
    text <- httr::content(req, as = "text", encoding = "UTF-8")
    # parse text to json
    asjson <- jsonlite::fromJSON(text)

    # Check for errors - if no error object, continue to process content
    if (is.null(asjson$error$id)) {
      # set error.id to OK
      error.id <- "OK"
      if (mode == "CAR") {
        # for car the distance is only recorded in the legs objects. Only one leg
        # should be returned if mode is car and we pick that
        response <-
          list(
            "errorId" = error.id,
            "distance" = asjson$plan$itineraries$legs[[1]]$distance
          )
        return (response)
        # for walk or cycle
      } else {
        response <-
          list("errorId" = error.id,
               "distance" = asjson$plan$itineraries$walkDistance)
        return (response)
      }
    } else {
      # there is an error - return the error code and message
      response <-
        list("errorId" = asjson$error$id,
             "errorMessage" = asjson$error$msg)
      return (response)
    }
  }
