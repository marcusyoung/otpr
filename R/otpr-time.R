#' Finds the time in minutes between supplied origin and destination
#'
#' Finds the time in minutes between supplied origin and destination by specified mode(s).
#' If \code{detail} is set to TRUE returns time for each mode, waiting time and number of transfers.
#'
#' @param otpcon An OTP connection object produced by \code{otp_connect()}.
#' @param fromPlace Numeric vector, Latitude/Longitude pair, e.g. `c(53.48805, -2.24258)`
#' @param toPlace Numeric vector, Latitude/Longitude pair, e.g. `c(53.36484, -2.27108)`
#' @param mode Character vector, mode(s) of travel. Valid values are: TRANSIT, WALK, BICYCLE,
#' CAR, BUS, RAIL, OR 'c("TRANSIT", "BICYCLE")'. Note that WALK mode is automatically
#' included for TRANSIT, BUS, and RAIL. Default is CAR.
#' @param date Character, must be in the format mm-dd-yyyy. This is the desired date of travel.
#' Only relevant for TRANSIT modes.
#' @param time Character, must be in the format hh:mm:ss.
#' If \code{arriveBy} is FALSE (the default) this is the desired departure time, otherwise the
#' desired arrival time.
#' @param arriveBy Logical. Default is FALSE.
#' @param maxWalkDistance Numeric. The maximum distance (in meters) the user is
#' willing to walk. Default = 800.
#' @param walkReluctance Integer. A multiplier for how bad walking is, compared
#' to being in transit for equal lengths of time. Default = 2.
#' @param transferPenalty Integer. An additional penalty added to boardings after
#' the first. The value is in OTP's internal weight units, which are roughly equivalent to seconds. Set this to a high value to discourage transfers. Default is 0.
#' @param minTransferTime Integer. The minimum time, in seconds, between successive
#' trips on different vehicles. This is designed to allow for imperfect schedule
#' adherence. This is a minimum; transfers over longer distances might use a longer time.
#' Default is 0.
#' @param detail Logical. Default is FALSE.
#' @return Returns a list. First element in the list is \code{errorId}. This is "OK" if
#' OTP has not returned an error. Otherwise it is the OTP error code. Second element of list
#' varies:
#' \itemize{
#' \item If OTP has retuned an error then \code{errorMessage} contains the OTP error message.
#' \item If there is no error and \code{detail} is FALSE then \code{duration} in minutes is returned as integer.
#' \item If there is no error and \code{detail} is TRUE then \code{itineraries} as a dataframe.
#' }
#' @export
#'
#'
otpr_time <-
  function(otpcon,
           fromPlace = NULL,
           toPlace = NULL,
           mode = "CAR",
           date = NULL,
           time = NULL,
           maxWalkDistance = 800,
           walkReluctance = 2,
           arriveBy = FALSE,
           transferPenalty = 0,
           minTransferTime = 0,
           detail = FALSE)
  {
    mode <- toupper(mode)

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
    checkmate::assert_int(walkReluctance, lower = 0, add = coll)
    checkmate::assert_int(transferPenalty, lower = 0, add = coll)
    checkmate::assert_int(minTransferTime, lower = 0, add = coll)
    checkmate::assert_number(minTransferTime, lower = 0, add = coll)
    checkmate::assert_logical(arriveBy, add = coll)
    checkmate::assert_logical(detail, add = coll)
    checkmate::reportAssertions(coll)

    fromPlace <- paste(fromPlace, collapse = ",")
    toPlace <- paste(toPlace, collapse = ",")

    # check for valid modes
    valid_mode <-
      list(
        c("TRANSIT"),
        c("WALK"),
        c("BICYCLE"),
        c("CAR"),
        c("BUS"),
        c("RAIL"),
        c("TRANSIT", "BICYCLE")
      )

    if (!(Position(function(x)
      identical(x, mode), valid_mode, nomatch = 0) > 0)) {
      stop(
        paste0(
          "Mode must be one of: 'TRANSIT', 'WALK', 'BICYCLE', 'CAR', 'BUS', 'RAIL',
          OR 'c('TRANSIT', 'BICYCLE')', but is '",
          mode,
          "'."
        )
      )
    }

    # add WALK to relevant modes

    if (mode == "TRANSIT" | mode == "BUS" | mode == "RAIL") {
      mode <- append(mode, "WALK")
    }

    mode <- paste(mode, collapse = ",")

    # check date and time are valid

    if (IsDate(date) == FALSE) {
      stop("date must be in the format mm-dd-yyyy")
    }

    if (IsTime(time) == FALSE) {
      stop("time must be in the format hh:mm:ss")
    }


    # Construct URL
    routerUrl <- make_url(otpcon)
    routerUrl <- paste0(routerUrl, "/plan")

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
    asjson <- jsonlite::fromJSON(text)

    # Check for errors - if no error object, continue to process content
    if (is.null(asjson$error$id)) {
      # set error.id to OK
      error.id <- "OK"
      # get first itinerary
      df <- asjson$plan$itineraries[1, ]
      # check if need to return detailed response
      if (detail == TRUE) {
        # need to convert times from epoch format
        df$start <-
          as.POSIXct(df$startTime / 1000, origin = "1970-01-01")
        df$end <-
          as.POSIXct(df$endTime / 1000, origin = "1970-01-01")
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
              'duration',
              'walkTime',
              'transitTime',
              'waitingTime',
              'transfers'
            )
          )
        # convert seconds into minutes where applicable
        ret.df[, 3:6] <- round(ret.df[, 3:6] / 60, digits = 2)
        # rename walkTime column as appropriate - this a mistake in OTP
        if (mode == "CAR") {
          names(ret.df)[names(ret.df) == 'walkTime'] <- 'driveTime'
        } else if (mode == "BICYCLE") {
          names(ret.df)[names(ret.df) == 'walkTime'] <- 'cycleTime'
        }
        response <-
          list("errorId" = error.id, "itineraries" = ret.df)
        return (response)
      } else {
        # detail not needed - just return travel time in seconds
        response <-
          list("errorId" = error.id, "duration" = df$duration)
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
