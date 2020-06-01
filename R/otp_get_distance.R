#' Finds the distance in metres between supplied origin and destination
#'
#' Finds the distance in metres between supplied origin and destination. Only makes
#' sense for walk, cycle or car modes (not transit)
#'
#' @param otpcon An OTP connection object produced by \code{\link{otp_connect}}.
#' @param fromPlace Numeric vector, Latitude/Longitude pair, e.g. `c(53.48805, -2.24258)`
#' @param toPlace Numeric vector, Latitude/Longitude pair, e.g. `c(53.36484, -2.27108)`
#' @param mode Character vector, single mode of travel. Valid values are WALK, BICYCLE, or CAR. Default is CAR.
#' @return If OTP has not returned an error then a list containing \code{errorId}
#' with the value "OK", the \code{distance} in metres. If OTP has returned an
#' error then a list containing \code{errorId} with the OTP error code and \code{errorMessage}
#' with the error message returned by OTP. In both cases there will be a third element
#' named \code{query} which is a character string containing the URL that was submitted to the OTP API.
#' @examples \dontrun{
#' otp_get_distance(otpcon, fromPlace = c(53.48805, -2.24258), toPlace = c(53.36484, -2.27108))
#'
#' otp_get_distance(otpcon, fromPlace = c(53.48805, -2.24258), toPlace = c(53.36484, -2.27108),
#' mode = "WALK")
#'}
#' @export
otp_get_distance <-
  function(otpcon,
           fromPlace,
           toPlace,
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
    routerUrl <- paste0(make_url(otpcon)$router, "/plan")
    
    # Use GET from the httr package to make API call and place in req - returns json by default
    req <- httr::GET(routerUrl,
                     query = list(
                       fromPlace = fromPlace,
                       toPlace = toPlace,
                       mode = mode
                     ))
    # decode URL for return
    url <- urltools::url_decode(req$url)
    
    # convert response content into text
    text <- httr::content(req, as = "text", encoding = "UTF-8")
    # parse text to json
    asjson <- jsonlite::fromJSON(text)
    
    # Check for errors
    if (!is.null(asjson$error$id)) {
      response <-
        list(
          "errorId" = asjson$error$id,
          "errorMessage" = asjson$error$msg,
          "query" = url
        )
      return (response)
    } else {
      error.id <- "OK"
    }
    
    # OTPv2 does not always return an error when there is no itinerary. So now
    # also check that there is at least 1 itinerary present.
    if (length(asjson$plan$itineraries) == 0) {
      response <-
        list(
          "errorId" = -9999,
          "errorMessage" = "No itinerary returned.",
          "query" = url
        )
      return (response)
    }
    
    if (mode == "CAR") {
      # for car the distance is only recorded in the legs objects. Only one leg
      # should be returned if mode is car and we pick that
      response <-
        list(
          "errorId" = error.id,
          "distance" = asjson$plan$itineraries$legs[[1]]$distance,
          "query" = url
        )
      return (response)
      # for walk or cycle
    } else {
      response <-
        list(
          "errorId" = error.id,
          "distance" = asjson$plan$itineraries$walkDistance,
          "query" = url
        )
      return (response)
    }
  }
