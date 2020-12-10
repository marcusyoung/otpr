#' Creates a travel time surface for an origin point. A surface has the travel time
#' to every geographic coordinate that can be reached from that origin. (OTPv1 only)
#'
#' Returns information about the created surface.
#' @param otpcon An OTP connection object produced by \code{\link{otp_connect}}.
#' @param getRaster Logical. Whether to download a raster (tiff) of the generated
#' surface. Default FALSE.
#' @param rasterPath Character. Path of a directory to save the surface raster.
#' Default is \code{tempdir()}. File will be named surface_{id}.tiff, with {id}
#' replaced with the id of the surface.
#' @param location Numeric vector, Latitude/Longitude pair, e.g. `c(53.48805, -2.24258)`
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
#' @param arriveBy Logical. Whether the specified date and time is for
#' departure (FALSE) or arrival (TRUE). Default is FALSE.
#' @param maxWalkDistance Numeric. The maximum distance (in meters) the user is
#' willing to walk. Default = 800.
#' @param walkReluctance Integer. A multiplier for how bad walking is, compared
#' to being in transit for equal lengths of time. Default = 2.
#' @param transferPenalty Integer. An additional penalty added to boardings after
#' the first. The value is in OTP's internal weight units, which are roughly equivalent
#' to seconds. Set this to a high value to discourage transfers. Default is 0.
#' @param minTransferTime Integer. The minimum time, in seconds, between successive
#' trips on different vehicles. This is designed to allow for imperfect schedule
#' adherence. This is a minimum; transfers over longer distances might use a longer time.
#' Default is 0.
#' @return Returns ...
#' @examples \dontrun{
#'
#'}
#' @export
otp_create_surface <-
  function(otpcon,
           getRaster = FALSE,
           rasterPath = tempdir(),
           location,
           mode = "TRANSIT",
           date,
           time,
           arriveBy = FALSE,
           maxWalkDistance = 800,
           walkReluctance = 2,
           transferPenalty = 0,
           minTransferTime = 0)
  {
    if (otpcon$version != 1) {
      stop(
        "OTP server is running OTPv",
        otpcon$version,
        ". otp_create_surface() is only supported in OTPv1"
      )
    }
    
    
    # /otp/surface API endpoint must be enabled on the OTP instance (requires --analyst on launch)
    req <-
      try(httr::GET(paste0(make_url(otpcon)$otp, "/surfaces")), silent = T)
    if (class(req) == "try-error") {
      stop("Unable to connect to OTP. Does ",
           make_url(otpcon)$otp,
           " even exist?")
    } else if
      (req$status_code != 200) {
        stop(
          "Unable to connect to surface API. Was ",
          make_url(otpcon)$otp,
          " launched in analyst mode using --analyst ?"
        )
      }
    
    
    if (missing(date)) {
      date <- format(Sys.Date(), "%m-%d-%Y")
    }
    
    if (missing(time)) {
      time <- format(Sys.time(), "%H:%M:%S")
    }
    
    # allow lowercase
    mode <- toupper(mode)
    
    #argument checks
    
    coll <- checkmate::makeAssertCollection()
    checkmate::assert_class(otpcon, "otpconnect", add = coll)
    checkmate::assert_numeric(
      location,
      lower =  -180,
      upper = 180,
      len = 2,
      add = coll
    )
    checkmate::assert_int(maxWalkDistance, lower = 0, add = coll)
    checkmate::assert_int(walkReluctance, lower = 0, add = coll)
    checkmate::assert_int(transferPenalty, lower = 0, add = coll)
    checkmate::assert_int(minTransferTime, lower = 0, add = coll)
    checkmate::assert_logical(arriveBy, add = coll)
    checkmate::assert_choice(
      mode,
      choices = c("WALK", "BUS", "RAIL", "TRANSIT", "BICYCLE", "CAR"),
      null.ok = F,
      add = coll
    )
    checkmate::reportAssertions(coll)
    
    
    # add WALK to relevant modes
    if (identical(mode, "TRANSIT") |
        identical(mode, "BUS") |
        identical(mode, "RAIL")) {
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
    surfaceUrl <- paste0(make_url(otpcon)$otp, "/surfaces")
    
    
    req <- httr::POST(
      surfaceUrl,
      query =
        list(
          batch = TRUE,
          fromPlace = paste(location, collapse = ","),
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
    
    # decode URL for return
    url <- urltools::url_decode(req$url)
    
    # convert response content into text
    text <- httr::content(req, as = "text", encoding = "UTF-8")
    
    # Check that a surface is returned
    if (grepl("\"id\":", text)) {
      errorId <- "OK"
      surfaceId <-
        as.numeric(regmatches(text, regexec('id\":(.{1,3}),', text))[[1]][2])
      surfaceRecord <- text
      if (getRaster == TRUE) {
        download_path <- paste0(rasterPath, "/surface_", surfaceId, ".tiff")
        # need check here
        check <-
          try(httr::GET(
            paste0(surfaceUrl, "/", surfaceId, "/raster"),
            write_disk(download_path, overwrite = TRUE)
          ), silent = T)
        if (class(check) == "try-error") {
          rasterDownload <- check[1]
        } else{
          rasterDownload <- check$request$output$path
        }
      } else {
        rasterDownload <- "Not requested"
      }
    } else {
      response <-
        list(
          "errorId" = "ERROR",
          "errorMessage" = "A surface was not successfully created",
          "query" = url
        )
      return (response)
    }
    
    response <-
      list(
        "errorId" = errorId,
        "surfaceId" = surfaceId,
        "surfaceRecord" = surfaceRecord,
        "query" = url,
        "rasterDownload" = rasterDownload
      )
    return (response)
    
  }
