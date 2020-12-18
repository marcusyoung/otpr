#' Returns one or more travel time isochrones (OTPv1 only)
#'
#' Returns one or more travel time isochrone in either GeoJSON format or as an
#' \strong{sf} object. Only works correctly for walk and/or transit modes - a limitation
#' of OTP. Isochrones can be generated either \emph{from} a location or \emph{to}
#' a location.
#' @param otpcon An OTP connection object produced by \code{\link{otp_connect}}.
#' @param location Numeric vector, Latitude/Longitude pair, e.g. `c(53.48805, -2.24258)`
#' @param fromLocation Logical. If TRUE (default) the isochrone
#' will be generated \emph{from} the \code{location}. If FALSE the isochrone will
#' be generated \emph{to} the \code{location}.
#' @param format Character, required format of returned isochrone(s). Either JSON
#' (returns GeoJSON) or SF (returns simple feature collection). Default is JSON.
#' @param mode Character, mode of travel. Valid values are: WALK, TRANSIT, BUS,
#' or RAIL. 
#' Note that WALK mode is automatically included for TRANSIT, BUS and RAIL.
#' TRANSIT will use all available transit modes. Default is TRANSIT.
#' @param date Character, must be in the format mm-dd-yyyy. This is the desired
#' date of travel. Only relevant if \code{mode} includes public transport.
#' Default is current system date.
#' @param time Character, must be in the format hh:mm:ss. If \code{arriveBy} is
#' FALSE (the default) this is the desired departure time, otherwise the desired
#' arrival time. Default is current system time.
#' @param cutoffs Numeric vector, containing the cutoff times in seconds, for
#' example: 'c(900, 1800, 2700)'
#' would request 15, 30 and 60 minute isochrones. Can be a single value.
#' @param batch Logical. If true, goal direction is turned off and a full path tree is built
#' @param arriveBy Logical. Whether the specified date and time is for
#' departure (FALSE) or arrival (TRUE). Default is FALSE.
#' @param maxWalkDistance Numeric. The maximum distance (in meters) the user is
#' willing to walk. Default = 800 (approximately 10-minutes at 3 mph). This is a
#' soft limit in OTPv1 and is effectively ignored if the mode is WALK only. In OTPv2
#' this parameter imposes a hard limit for all modes - including WALK only (see:
#' \url{http://docs.opentripplanner.org/en/latest/OTP2-MigrationGuide/#router-config}).
#' @param walkReluctance A single numeric value. A multiplier for how bad walking is, compared
#' to being in transit for equal lengths of time. Default = 2.
#' @param waitReluctance A single numeric value. A multiplier for how bad waiting for a
#' transit vehicle is compared to being on a transit vehicle. This should be greater
#' than 1 and less than \code{walkReluctance} (see API docs). Default = 1.
#' @param transferPenalty Integer. An additional penalty added to boardings after
#' the first. The value is in OTP's internal weight units, which are roughly equivalent
#' to seconds. Set this to a high value to discourage transfers. Default is 0.
#' @param minTransferTime Integer. The minimum time, in seconds, between successive
#' trips on different vehicles. This is designed to allow for imperfect schedule
#' adherence. This is a minimum; transfers over longer distances might use a longer time.
#' Default is 0.
#' @param ... Any other parameter:value pair accepted by the OTP API LIsochrone entry point. Be aware
#' that otpr will carry out no validation of these additional parameters. They will be passed directly
#' to the API. 
#' @return Returns a list. First element in the list is \code{errorId}. This is "OK" if
#' OTP successfully returned the isochrone(s), otherwise it is "ERROR". The second
#' element of list varies:
#' \itemize{
#' \item If \code{errorId} is "ERROR" then \code{response} contains the OTP error message.
#' \item If \code{errorId} is "OK" then \code{response} contains the the isochrone(s) in
#' either GeoJSON format or as an \strong{sf} object, depending on the value of the
#' \code{format} argument.
#' }
#' The third element of the list is \code{query} which is a character string containing the URL
#' that was submitted to the OTP API.
#' @examples \dontrun{
#' otp_get_isochrone(otpcon, location = c(53.48805, -2.24258), cutoffs = c(900, 1800, 2700))
#'
#' otp_get_isochrone(otpcon, location = c(53.48805, -2.24258), fromLocation = FALSE,
#' cutoffs = c(900, 1800, 2700), mode = "BUS")
#'}
#' @export
otp_get_isochrone <-
  function(otpcon,
           location,
           fromLocation = TRUE,
           format = "JSON",
           mode = "TRANSIT",
           date = format(Sys.Date(), "%m-%d-%Y"),
           time = format(Sys.time(), "%H:%M:%S"),
           cutoffs,
           batch = TRUE,
           arriveBy = FALSE,
           maxWalkDistance = 800,
           walkReluctance = 2,
           waitReluctance = 1,
           transferPenalty = 0,
           minTransferTime = 0,
           ...)
  {
    # get the OTP parameters ready to pass to check function
    
    call <- sys.call()
    call[[1]] <- as.name('list')
    params <- eval.parent(call)
    params <-
      params[names(params) %in% c("mode", "location", "fromLocation", "format") == FALSE]
    
        if (otpcon$version != 1) {
      stop(
        "OTP server is running OTPv",
        otpcon$version,
        ". otp_get_isochrone() is only supported in OTPv1"
      )
    }
    
    # allow lowercase
    format <- toupper(format)
    mode <- toupper(mode)
    
    # function specific argument checks
    args.coll <- checkmate::makeAssertCollection()
    checkmate::assert_logical(fromLocation, add = args.coll)
    checkmate::assert_logical(batch, add = args.coll)
    checkmate::assert_numeric(
      location,
      lower =  -180,
      upper = 180,
      len = 2,
      add = args.coll
    )
    # Mode is restricted for the isochrone function
    checkmate::assert_choice(
      mode,
      choices = c("WALK", "BUS", "RAIL", "TRANSIT"),
      null.ok = F,
      add = args.coll
    )
    checkmate::assert_choice(
      format,
      choices = c("JSON", "SF"),
      null.ok = FALSE,
      add = args.coll
    )
    checkmate::reportAssertions(args.coll)
    
    # add WALK to relevant modes
    if (identical(mode, "TRANSIT") |
        identical(mode, "BUS") |
        identical(mode, "RAIL")) {
      mode <- append(mode, "WALK")
    }
    
    mode <- paste(mode, collapse = ",")
    
    # OTP API parameter checks
    do.call(otp_check_params,
            params)
    
    # Construct URL
    routerUrl <- paste0(make_url(otpcon)$router, "/isochrone")
    
    # make cutoffs into list
    cutoffs <- as.list(cutoffs)
    names(cutoffs) <- rep("cutoffSec", length(cutoffs))
    
    if (isTRUE(fromLocation)) {
      req <- httr::GET(routerUrl,
                       query =
                         append(
                           list(
                             fromPlace = paste(location, collapse = ","),
                             mode = mode,
                             batch = batch,
                             date = date,
                             time = time,
                             maxWalkDistance = maxWalkDistance,
                             walkReluctance = walkReluctance,
                             arriveBy = arriveBy,
                             transferPenalty = transferPenalty,
                             minTransferTime = minTransferTime
                           ),
                           cutoffs,
                           list(...)
                         ))
    } else {
      # due to OTP bug when we require an isochrone to the location we must provide the
      # location in toPlace, but also provide fromPlace (which is ignored). Here we
      # make fromPlace the same as toPlace.
      req <- httr::GET(routerUrl,
                       query =
                         append(
                           list(
                             toPlace = paste(location, collapse = ","),
                             fromPlace = paste(location, collapse = ","),
                             # due to OTP bug
                             mode = mode,
                             batch = batch,
                             date = date,
                             time = time,
                             maxWalkDistance = maxWalkDistance,
                             walkReluctance = walkReluctance,
                             arriveBy = arriveBy,
                             transferPenalty = transferPenalty,
                             minTransferTime = minTransferTime
                           ),
                           cutoffs,
                           list(...)
                         ))
    }
    
    # decode URL for return
    url <- urltools::url_decode(req$url)
    
    # convert response content into text
    text <- httr::content(req, as = "text", encoding = "UTF-8")
    
    # Check that GeoJSON is returned
    if (grepl("\"type\":\"FeatureCollection\"", text)) {
      errorId <- "OK"
      isochrone <- text
      # convert to SF if requested
      if (format == "SF") {
        isochrone <- geojsonsf::geojson_sf(isochrone)
        # correct invalid geometry that OTP tends to return
        isochrone <- sf::st_make_valid(isochrone)
      }
    } else {
      errorId <- "ERROR"
    }
    
    response <-
      list("errorId" = errorId,
           "response" = isochrone,
           "query" = url)
    return (response)
  }
