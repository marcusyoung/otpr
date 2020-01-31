#' Finds the time in minutes between supplied origin and destination
#'
#' Finds the time in minutes between supplied origin and destination by specified mode(s).
#' If \code{detail} is set to TRUE returns time for each mode, waiting time and number of transfers.
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
#' willing to walk. Default = 800.
#' @param walkReluctance Integer. A multiplier for how bad walking is, compared
#' to being in transit for equal lengths of time. Default = 2.
#' @param transferPenalty Integer. An additional penalty added to boardings after
#' the first. The value is in OTP's internal weight units, which are roughly equivalent to seconds. Set this to a high
#' value to discourage transfers. Default is 0.
#' @param minTransferTime Integer. The minimum time, in seconds, between successive
#' trips on different vehicles. This is designed to allow for imperfect schedule
#' adherence. This is a minimum; transfers over longer distances might use a longer time.
#' Default is 0.
#' @param detail Logical. Default is FALSE.
#' @param includeLegs Logical. Default is FALSE. Determines whether or not details of each journey leg are returned. If TRUE then a dataframe of journeys legs will be returned but only when \code{detail} is TRUE and \code{mode} contains transit modes (Legs are not relevant for CAR, BICYCLE or WALK modes).
#' @return Returns a list. First element in the list is \code{errorId}. This is "OK" if
#' OTP has not returned an error. Otherwise it is the OTP error code. Second element of list
#' varies:
#' \itemize{
#' \item If OTP has returned an error then \code{errorMessage} contains the OTP error message.
#' \item If there is no error and \code{detail} is FALSE then \code{duration} in minutes is returned as integer.
#' \item If there is no error and \code{detail} is TRUE then \code{itineraries} as a dataframe.
#' \item If there is no error and \code{detail} and \code{legs} are both TRUE then \code{itineraries} as a dataframe and \code{legs} as a dataframe.
#' }
#' @examples \dontrun{
#' otp_get_times(otpcon, fromPlace = c(53.48805, -2.24258), toPlace = c(53.36484, -2.27108))
#'
#' otp_get_times(otpcon, fromPlace = c(53.48805, -2.24258), toPlace = c(53.36484, -2.27108),
#' mode = "BUS", date = "03-26-2019", time = "08:00:00")
#'
#' otp_get_times(otpcon, fromPlace = c(53.48805, -2.24258), toPlace = c(53.36484, -2.27108),
#' mode = "BUS", date = "03-26-2019", time = "08:00:00", detail = TRUE)
#'}
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
          "Mode must be one of: 'TRANSIT', 'WALK', 'BICYCLE', 'CAR', 'BUS', 'RAIL',
          or 'c('TRANSIT', 'BICYCLE')', but is '",
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
      # set flag so know dealing with transit modes
      transitModes <- TRUE
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
    routerUrl <- paste0(make_url(otpcon), "/plan")

    # Use GET from the httr package to make API call and place in req - returns json by default.
    # Not using numItineraries due to odd OTP behaviour - if request only 1 itinerary don't
    # necessarily get the top/best itinerary, sometimes a suboptimal itinerary is returned.
    # OTP will return default number of itineraries depending on mode. This function returns
    # the first of those itineraries.
    req <- httr::GET(
      routerUrl,
      query = list(
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
    )

    # convert response content into text
    text <- httr::content(req, as = "text", encoding = "UTF-8")
    # parse text to json
    asjson <- jsonlite::fromJSON(text, flatten = TRUE)

    # Check for errors - if no error object, continue to process content
    if (is.null(asjson$error$id)) {
      # set error.id to OK
      error.id <- "OK"
      # get first itinerary
      df <- asjson$plan$itineraries[1,]
      # check if need to return detailed response
      if (detail == TRUE) {
        # need to convert times from epoch format
        df$start <-
          as.POSIXct(df$startTime / 1000, origin = "1970-01-01", tz = otpcon$tz)
        df$end <-
          as.POSIXct(df$endTime / 1000, origin = "1970-01-01", tz = otpcon$tz)
        df$timeZone <- attributes(df$start)$tzone[1]
        # create new columns for nicely formatted dates and times
        #df$startDate <- format(start.time, "%d-%m-%Y")
        #df$startTime <- format(start.time, "%I:%M%p")
        #df$endDate <- format(end.time, "%d-%m-%Y")
        #df$endTime <- format(end.time, "%I:%M%p")
        # subset the dataframe ready to return
        ret.df <-
          subset(
            df,
            select = c(
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
        # convert seconds into minutes where applicable
        ret.df[, 4:7] <- round(ret.df[, 4:7] / 60, digits = 2)
        # rename walkTime column as appropriate - this a mistake in OTP
        if (mode == "CAR") {
          names(ret.df)[names(ret.df) == 'walkTime'] <- 'driveTime'
        } else if (mode == "BICYCLE") {
          names(ret.df)[names(ret.df) == 'walkTime'] <- 'cycleTime'
        }
        response <-
          list("errorId" = error.id, "itineraries" = ret.df)
        # get and process legs if required
        if (isTRUE(transitModes & isTRUE(includeLegs))) {
          legs <- df$legs[[1]]
          legs <- janitor::clean_names(legs, case = "lower_camel")

          legs$startTime <-
            as.POSIXct(legs$startTime / 1000,
                       origin = "1970-01-01",
                       tz = otpcon$tz)
          legs$endTime <-
            as.POSIXct(legs$endTime / 1000,
                       origin = "1970-01-01",
                       tz = otpcon$tz)
          legs$fromArrival <-
            as.POSIXct(legs$fromArrival / 1000,
                       origin = "1970-01-01",
                       tz = otpcon$tz)
          legs$fromDeparture <-
            as.POSIXct(legs$fromDeparture / 1000,
                       origin = "1970-01-01",
                       tz = otpcon$tz)

          legs$departureWait <-
            round(abs((
              as.numeric(legs$fromArrival - legs$fromDeparture)
            ) / 60), 2)

          legs$departureWait[is.na(legs$departureWait)] <- 0

          legs$duration <- round(legs$duration / 60, 2)

          legs$timeZone <- attributes(legs$startTime)$tzone[1]

          ret.legs <- subset(
            legs,
            select = c(
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
          )

          response[["legs"]] <- ret.legs
        }
        return (response)
      } else {
        # detail not needed - just return travel time in minutes
        response <-
          list("errorId" = error.id,
               "duration" = round(df$duration / 60, digits = 2))
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
