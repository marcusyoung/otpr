#' Creates a travel time surface (OTPv1 only).
#' 
#' Creates a travel time surface for an origin point. A surface contains the travel time
#' to every geographic coordinate that can be reached from that origin. Optionally, the surface
#' can be saved as a raster file (GeoTIFF) to the designated directory.
#'
#' @param otpcon An OTP connection object produced by \code{\link{otp_connect}}.
#' @param getRaster Logical. Whether or not to download a raster (geoTIFF) of the generated
#' surface. Default FALSE.
#' @param rasterPath Character. Path of a directory where the the surface raster
#' should be saved. Default is \code{tempdir()}. The file will be named 
#' surface_{id}.tiff, with {id} replaced by the OTP id assigned to the surface.
#' @param origin Numeric vector, Latitude/Longitude pair, e.g. `c(53.48805, -2.24258)`
#' @param mode Character, mode of travel. Valid values are: WALK, TRANSIT, BUS,
#' or RAIL.
#' Note that WALK mode is automatically included for TRANSIT, BUS and RAIL.
#' TRANSIT will use all available transit modes. Default is TRANSIT.
#' @param date Character, must be in the format mm-dd-yyyy. This is the desired
#' date of travel. Only relevant if \code{mode} includes public transport.
#' Default is current system date.
#' @param time Character, must be in the format hh:mm:ss. This is the desired 
#' departure time. Default is current system time.
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
#' @return A list of 5 items:
#' \itemize{
#' \item \code{errorId} - character, should be "OK" if no error condition.
#' \item \code{query} - this is a character string containing the URL.
#' that was submitted to the OTP API.
#' \item \code{surfaceId} - integer, the id of the surface that was evaluated.
#' \item \code{surfaceRecord} - details of the parameters used to create the surface.
#' \item \code{rasterDownload} - the path to the saved raster file (if \code{getRaster} was 
#' set to TRUE and a valid path was provided via \code{rasterPath}.)
#' }
#' @examples \dontrun{
#' otp_create_surface(otpcon, origin = c(53.43329,-2.13357), mode = "TRANSIT", 
#' maxWalkDistance = 1600, getRaster = TRUE)
#' 
#' otp_create_surface(otpcon, origin = c(53.43329,-2.13357), date = "03-26-2019",
#' time = "08:00:00", mode = "BUS", maxWalkDistance = 1600, getRaster = TRUE)
#'}
#' @export
otp_create_surface <-
  function(otpcon,
           getRaster = FALSE,
           rasterPath = tempdir(),
           origin,
           mode = "TRANSIT",
           date,
           time,
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
      origin,
      lower =  -180,
      upper = 180,
      len = 2,
      add = coll
    )
    checkmate::assert_int(maxWalkDistance, lower = 0, add = coll)
    checkmate::assert_int(walkReluctance, lower = 0, add = coll)
    checkmate::assert_int(transferPenalty, lower = 0, add = coll)
    checkmate::assert_int(minTransferTime, lower = 0, add = coll)
    checkmate::assert_choice(
      mode,
      choices = c("WALK", "BUS", "RAIL", "TRANSIT", "BICYCLE", "CAR"),
      null.ok = F,
      add = coll
    )
    checkmate::assert_path_for_output(file.path(rasterPath, paste0("surface_", surfaceId, ".tiff"), fsep = .Platform$file.sep), overwrite = TRUE, add = coll)
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
          fromPlace = paste(origin, collapse = ","),
          mode = mode,
          date = date,
          time = time,
          maxWalkDistance = maxWalkDistance,
          walkReluctance = walkReluctance,
          arriveBy = FALSE,
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
        download_path <- file.path(rasterPath, paste0("surface_", surfaceId, ".tiff"), fsep = .Platform$file.sep)
        check <-
          try(httr::GET(
            paste0(surfaceUrl, "/", surfaceId, "/raster"),
            httr::write_disk(download_path, overwrite = TRUE)
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
        "query" = url,
        "surfaceId" = surfaceId,
        "surfaceRecord" = surfaceRecord,
        "rasterDownload" = rasterDownload
      )
    return (response)
    
  }
