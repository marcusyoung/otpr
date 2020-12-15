#' Queries OTP for trip time between an origin and destination or detailed itineraries
#'
#' In the simplest use case, returns the time in minutes between supplied origin
#' and destination by specified mode(s) for the top itinerary returned by OTP. If
#' \code{detail} is set to TRUE one or more detailed trip itineraries are returned,
#' including the time for each mode (if a multimodal trip), waiting time and the
#' number of transfers. Optionally, the details of each journey leg for each itinerary
#' can be returned.
#'
#' @param otpcon An OTP connection object produced by \code{\link{otp_connect}}.
#' @param fromPlace Numeric vector, Latitude/Longitude pair, e.g. `c(53.48805, -2.24258)`
#' @param toPlace Numeric vector, Latitude/Longitude pair, e.g. `c(53.36484, -2.27108)`
#' @param mode Character vector, mode(s) of travel. Valid values are: TRANSIT, WALK, BICYCLE,
#' CAR, BUS, RAIL, OR 'c("TRANSIT", "BICYCLE")'. Note that WALK mode is automatically
#' included for TRANSIT, BUS, and RAIL. TRANSIT will use all available transit modes. Default is CAR.
#' @param date Character, must be in the format mm-dd-yyyy. This is the desired date of travel.
#' Only relevant if \code{mode} includes public transport. Default is current system date.
#' @param time Character, must be in the format hh:mm:ss.
#' If \code{arriveBy} is FALSE (the default) this is the desired departure time, otherwise the
#' desired arrival time. Only relevant if \code{mode} includes public transport.
#' Default is current system time.
#' @param arriveBy Logical. Whether trip should depart (FALSE) or arrive (TRUE) at the specified
#' date and time. Default is FALSE.
#' @param maxWalkDistance Numeric. The maximum distance (in meters) the user is
#' willing to walk. Default = 800 (approximately 10-minutes at 3 mph). This is a
#' soft limit in OTPv1 and is effectively ignored if the mode is WALK only. In OTPv2
#' this parameter imposes a hard limit for all modes - including WALK only (see:
#' \url{http://docs.opentripplanner.org/en/latest/OTP2-MigrationGuide/#router-config}).
#' @param walkReluctance Integer. A multiplier for how bad walking is, compared
#' to being in transit for equal lengths of time. Default = 2.
#' @param transferPenalty Integer. An additional penalty added to boardings after
#' the first. The value is in OTP's internal weight units, which are roughly equivalent to seconds.
#' Set this to a high value to discourage transfers. Default is 0.
#' @param minTransferTime Integer. The minimum time, in seconds, between successive
#' trips on different vehicles. This is designed to allow for imperfect schedule
#' adherence. This is a minimum; transfers over longer distances might use a longer time.
#' Default is 0.
#' @param maxItineraries Integer. Controls the number of trip itineraries that
#' are returned. This is not an OTP parameter. All suggested itineraries are allowed to be
#' returned by the OTP server. otpr will then return them to the user in the order
#' they were provided by OTP up to the maximum specified by this parameter. Default is 1.
#' @param detail Logical. This parameter only has an effect when \code{detail} is set
#' to true. When \code{detail} is set to FALSE only a single trip time is returned. Default is FALSE.
#' @param includeLegs Logical. Default is FALSE. Determines whether or not details of each
#' journey leg are returned. If TRUE then a dataframe of journeys legs will be returned but
#' only when \code{detail} is also TRUE.
#' @return Returns a list of three or four elements. First element in the list is \code{errorId}.
#' This is "OK" if OTP has not returned an error. Otherwise it is the OTP error code. Second element of list
#' varies:
#' \itemize{
#' \item If OTP has returned an error then \code{errorMessage} contains the OTP error message.
#' \item If there is no error and \code{detail} is FALSE then the \code{duration} in minutes is
#' returned as an integer. This is the duration of the top itinerary returned by the OTP server.
#'
#' \item If there is no error and \code{detail} is TRUE then \code{itineraries} as a dataframe.
#' }
#' The third element of the list is \code{query}. This is a character string containing the URL
#' that was submitted to the OTP API.
#' @details
#' If you plan to use the function in simple-mode - where just the duration of the top itinerary is returned -
#' it is advisable to first review several detailed itineraries to ensure that the parameters
#' you have set are producing sensible results.
#'
#' If requested, the itineraries dataframe will include a column called legs which
#' contains a nested dataframe for each itinerary. Each legs dataframe will contain
#' a set of core columns that are consistent across all queries. However, as the OTP
#' API does not consistently return the same attributes for legs, there will be some variation
#' in columns returned. You should bare this in mind if your post processing
#' uses these columns (e.g. by checking for column existence).
#' @examples \dontrun{
#' otp_get_times(otpcon, fromPlace = c(53.48805, -2.24258), toPlace = c(53.36484, -2.27108))
#'
#' otp_get_times(otpcon, fromPlace = c(53.48805, -2.24258), toPlace = c(53.36484, -2.27108),
#' mode = "BUS", date = "03-26-2019", time = "08:00:00")
#'
#' otp_get_times(otpcon, fromPlace = c(53.48805, -2.24258), toPlace = c(53.36484, -2.27108),
#' mode = "BUS", date = "03-26-2019", time = "08:00:00", detail = TRUE)
#'}
#' @importFrom rlang .data
#' @importFrom dplyr any_of
#' @export
otp_get_times <-
  function(otpcon,
           fromPlace,
           toPlace,
           mode = "CAR",
           date,
           time,
           maxWalkDistance = 800,
           walkReluctance = 2,
           arriveBy = FALSE,
           transferPenalty = 0,
           minTransferTime = 0,
           maxItineraries = 1,
           detail = FALSE,
           includeLegs = FALSE)
  {
    mode <- toupper(mode)
    
    
    if (missing(date)) {
      date <- format(Sys.Date(), "%m-%d-%Y")
    }
    
    if (missing(time)) {
      time <- format(Sys.time(), "%H:%M:%S")
    }
    
    
    #argument checks
    
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
    checkmate::assert_integerish(maxItineraries,
                                 lower = 1,
                                 add = coll)
    checkmate::assert_int(maxWalkDistance, lower = 0, add = coll)
    checkmate::assert_int(walkReluctance, lower = 0, add = coll)
    checkmate::assert_int(transferPenalty, lower = 0, add = coll)
    checkmate::assert_int(minTransferTime, lower = 0, add = coll)
    checkmate::assert_logical(detail, add = coll)
    checkmate::reportAssertions(coll)
    
    fromPlace <- paste(fromPlace, collapse = ",")
    toPlace <- paste(toPlace, collapse = ",")
    
    # check for valid modes
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
          mode,
          "'."
        )
      )
    }
    
    # add WALK to relevant modes - as mode may be a vector of length > 1 use identical
    # otpr_vectorMatch is TRUE if mode is c("TRANSIT", "BICYCLE") or c("BICYCLE", "TRANSIT")
    
    if (identical(mode, "TRANSIT") |
        identical(mode, "BUS") |
        identical(mode, "RAIL") |
        otp_vector_match(mode, c("TRANSIT", "BICYCLE"))) {
      mode <- append(mode, "WALK")
    }
    
    mode <- paste(mode, collapse = ",")
    
    # check date and time are valid
    
    if (otp_is_date(date) == FALSE) {
      stop("date must be in the format mm-dd-yyyy")
    }
    
    if (otp_is_time(time) == FALSE) {
      stop("time must be in the format hh:mm:ss")
    }
    
    
    # Construct URL
    routerUrl <- paste0(make_url(otpcon)$router, "/plan")
    
    # Construct query list
    query <- list(
      fromPlace = fromPlace,
      toPlace = toPlace,
      mode = mode,
      date = date,
      time = time,
      maxWalkDistance = maxWalkDistance,
      walkReluctance = walkReluctance,
      arriveBy = arriveBy,
      transferPenalty = transferPenalty,
      minTransferTime = minTransferTime
    )
    
    
    # Use GET from the httr package to make API call and place in req - returns json by default.
    req <- httr::GET(routerUrl,
                     query = query)
    
    # decode URL for return
    url <- urltools::url_decode(req$url)
    
    # convert response content into text
    text <- httr::content(req, as = "text", encoding = "UTF-8")
    # parse text to json
    asjson <- jsonlite::fromJSON(text, flatten = TRUE)
    
    # Check for errors
    # Note that OTPv1 and OTPv2 use a different node name for the error message.
    if (!is.null(asjson$error$id)) {
      response <-
        list(
          "errorId" = asjson$error$id,
          "errorMessage" = ifelse(
            otpcon$version == 1,
            asjson$error$msg,
            asjson$error$message
          ),
          "query" = url
        )
      return (response)
    } else {
      error.id <- "OK"
    }
    
    # Is this still the case v v2.0.0?
    # OTPv2 does not return an error when there is no itinerary - for
    # example if date is out of range of the GTFS schedules. So now also check that
    # there is at least 1 itinerary present.
    if (length(asjson$plan$itineraries) == 0) {
      response <-
        list(
          "errorId" = -9999,
          "errorMessage" = "No itinerary returned. If using OTPv2 you might be trying to plan a trip on a date not covered by the transit schedules.",
          "query" = url
        )
      return (response)
    }
    
    
    # check if need to return detailed response
    if (detail == TRUE) {
      # Return up to maxItineraries
      num_itin <-
        pmin(maxItineraries, nrow(asjson$plan[["itineraries"]]))
      df <- asjson$plan$itineraries[c(1:num_itin),]
      # need to convert times from epoch format
      df$start <-
        otp_from_epoch(df$startTime, otpcon$tz)
      df$end <-
        otp_from_epoch(df$endTime, otpcon$tz)
      df$timeZone <- attributes(df$start)$tzone[1]
      
      # If legs are required we process the nested legs dataframes preserving
      # structure using rrapply
      if (isTRUE(includeLegs)) {
        # clean-up colnnames
        legs <-
          rrapply::rrapply(
            df$legs,
            f = function(x)
              janitor::clean_names(x, case = "lower_camel"),
            classes = "data.frame"
          )
        # convert from epoch times
        legs <-
          rrapply::rrapply(
            legs,
            f = function(x, .xname)
              if (.xname == "startTime" |
                  .xname == "endTime" |
                  .xname == "fromDeparture" |
                  .xname == "fromArrival")
                otp_from_epoch(x, otpcon$tz)
            else
              x
          )
        # calculate departureWait - not relevant for one leg itineraries
        # (e.g. WALK only trip) where there won't be a fromArrival
        # However, for ease of processing of returned data we set departureWait
        # to zero for these.
        legs <-
          rrapply::rrapply(
            legs,
            f = function(x)
              if (nrow(x) > 1)
                dplyr::mutate(x, departureWait = round(abs((as.numeric(
                  .data$fromArrival - .data$fromDeparture
                )) / 60
                ), 2))
            else
              dplyr::mutate(x, departureWait = 0) ,
            classes = "data.frame"
          )
        # if departureWait is NA (usually for first leg of multi-leg trip) replace with 0
        legs <-
          rrapply::rrapply(
            legs,
            f = function(x, .xname)
              if (.xname == "departureWait")
                replace(x, is.na(x), 0)
            else
              x
          )
        # Update duration column to minutes
        legs <-
          rrapply::rrapply(
            legs,
            f = function(x, .xname)
              if (.xname == "duration")
                round(x / 60, 2)
            else
              x
          )
        # Add timezone column
        legs <-
          rrapply::rrapply(
            legs,
            f = function(x)
              dplyr::mutate(x, timeZone = attributes(x$startTime)$tzone[1]),
            classes = "data.frame"
          )
        
        
        # select required columns in legs using %in% as sometimes columns are missing
        # for example routeShortName. Also there are fewer columns when just a WALK,
        #BICYCLE or CAR leg # is returned.
        
        leg_columns <- c(
          'startTime',
          'endTime',
          'timeZone',
          'mode',
          'departureWait',
          'duration',
          'distance',
          'routeType',
          'routeId',
          'routeShortName',
          'routeLongName',
          'headsign',
          'agencyName',
          'agencyUrl',
          'agencyId',
          'fromName',
          'fromLon',
          'fromLat',
          'fromStopId',
          'fromStopCode',
          'toName',
          'toLon',
          'toLat',
          'toStopId',
          'toStopCode'
        )
        
        # Select columns
        legs <-
          rrapply::rrapply(
            legs,
            f = function(x)
              dplyr::select(x, which(colnames(x) %in%
                                       leg_columns)),
            classes = "data.frame"
          )
        
        # change column order using relocate
        legs <- rrapply::rrapply(
          legs,
          f = function(x)
            dplyr::relocate(x, any_of(leg_columns)),
          classes = "data.frame"
        )
        
      } # end legs processing
      
      # subset the dataframe ready to return
      ret.df <-
        dplyr::select(
          df,
          c(
            'start',
            'end',
            'timeZone',
            'duration',
            'walkTime',
            'transitTime',
            'waitingTime',
            'transfers'
          )
        )
      
      # Insert processed legs if required
      if (isTRUE(includeLegs)) {
        ret.df$legs <- legs
      }
      
      # convert seconds into minutes where applicable
      ret.df[, 4:7] <- round(ret.df[, 4:7] / 60, digits = 2)
      # rename walkTime column as appropriate - this a mistake in OTP
      if (mode == "CAR") {
        names(ret.df)[names(ret.df) == 'walkTime'] <- 'driveTime'
      } else if (mode == "BICYCLE") {
        names(ret.df)[names(ret.df) == 'walkTime'] <- 'cycleTime'
      }
      response <-
        list("errorId" = error.id,
             "itineraries" = ret.df,
             "query" = url)
      
      return (response)
    } else {
      # detail not needed - just return travel time in minutes from the first itinerary
      response <-
        list(
          "errorId" = error.id,
          "duration" = round(asjson$plan$itineraries[1, "duration"] / 60, digits = 2),
          "query" = url
        )
      return (response)
    }
  }
