#' Evaluates an existing travel time surface (OTPv1 only).
#'
#' Evaluates an existing travel time surface. Using a pointset from a specified CSV file,
#' the travel time to each point is obtained from the specified surface. Accessibility
#' indicators are then generated for one or more 'opportunity' columns in the pointset.
#' For example, you might have the number of jobs available at each location, or
#' the number of hospital beds.
#'
#' This function requires OTP to have been started with the \code{--analyst} switch and
#' the \code{--pointset} parameter set to the path of a directory containing the pointset file(s).
#'
#' @param otpcon An OTP connection object produced by \code{\link{otp_connect}}.
#' @param surfaceId Integer, the id number of an existing surface created using
#' \code{otp_create_surface()}.
#' @param pointset Character string, the name of a pointset known to OTP. A pointset
#' is contained in a CSV file present in the pointset directory location passed to
#' OTP at startup. The name of the pointset is the name of the file (without extension).
#' @param detail logical, whether the travel time from the surface origin to each
#' location in the pointset should be returned. Default is FALSE.
#' @return Assuming no error, returns a list containing 4 or more elements:
#' \itemize{
#' \item \code{errorId} Will be "OK" if no error condition.
#' \item \code{query} The URL that was submitted to the OTP API.
#' \item \code{surfaceId} The id of the surface that was evaluated.
#' \item One or more dataframes for each of the 'opportunity' columns in the pointset
#' CSV file. Each dataframe contains four columns:
#' \itemize{
#' \item minutes. The time from the surface origin in one-minute increments.
#' \item counts. The number of the opportunity locations
#' reached within each minute interval.
#' \item sum. The sum of the opportunities at each of
#' the locations reached within each minute interval.
#' \item cumsums. A cumulative sum of the opportunities reached.
#' }
#' \item If \code{detail} was set to TRUE then an additional dataframe containing
#' the time taken (in seconds) to reach each point in the pointset CSV file. If a
#' point was not reachable the time will be recorded as NA.
#' }
#' If there is an error, a list containing 3 elements is returned:
#' \itemize{
#' \item \code{errorId} The id code of the error.
#' \item \code{query} The URL that was submitted to the OTP API.
#' \item \code{errorMessage} The error message.
#' }
#' @examples \dontrun{
#' otp_evaluate_surface(otpcon, surfaceId = 0, pointset = "jobs", detail = TRUE)
#'}
#' @export
otp_evaluate_surface <-
  function(otpcon,
           surfaceId,
           pointset,
           detail = FALSE)
  {
    if (otpcon$version != 1) {
      stop(
        "OTP server is running OTPv",
        otpcon$version,
        ". otp_evaluate_surface() is only supported in OTPv1"
      )
    }
    
    # Check for required arguments
    if (missing(otpcon)) {
      stop("otpcon argument is required")
    } else if (missing(surfaceId)) {
      stop("surfaceId argument is required")
    } else if (missing(pointset)) {
      stop("pointset argument is required")
    }
    
    coll <- checkmate::makeAssertCollection()
    checkmate::assert_class(otpcon, "otpconnect", add = coll)
    checkmate::assert_integerish(surfaceId, add = coll)
    checkmate::assert_character(pointset, add = coll)
    checkmate::assert_logical(detail, add = coll)
    checkmate::reportAssertions(coll)
    
    
    
    # check for correct surface ID
    req <-
      try(httr::GET(paste0(make_url(otpcon)$otp, "/surfaces/", surfaceId)), silent = T)
    if (class(req) == "try-error") {
      stop(
        "Unable to connect to the OTP surfaces API endpoint. Was ",
        make_url(otpcon)$otp,
        " started with the --analysis switch?"
      )
    } else if (req$status_code != 200) {
      stop(
        "Unable to find surface id: ",
        surfaceId,
        ". Is the id correct? Has a surface been created first using otp_create_surface()?"
      )
    }
    
    
    # check for pointset
    req <-
      try(httr::GET(paste0(make_url(otpcon)$otp, "/pointsets/", pointset)), silent = T)
    if (class(req) == "try-error") {
      stop(
        "Unable to connect to the OTP pointsets API endpoint. Was ",
        make_url(otpcon)$otp,
        "started with the --analysis switch?"
      )
    } else if (req$status_code != 200) {
      stop(
        "Unable to find pointset: ",
        pointset,
        ". Is the name correct? Was OTP started with the --pointset switch and was a CSV file with this name located in the pointset directory when OTP was started?"
      )
    }
    
    
    # Construct URL
    indicatorUrl <-
      paste0(make_url(otpcon)$otp,
             "/surfaces/",
             surfaceId,
             "/indicator?targets=",
             pointset)
    
    
    req <- httr::GET(indicatorUrl,
                     query = list(detail = detail))
    
    # decode URL for return
    url <- urltools::url_decode(req$url)
    
    # convert response content into text
    text <- httr::content(req, as = "text", encoding = "UTF-8")
    
    # Should validate that text is JSON using jsonlite::validate()
    # parse text to json
    asjson <- jsonlite::fromJSON(text, flatten = TRUE)
    
    # Check for errors
    # Not sure if this is needed or correct for this endpoint as difficult to produce an error condition
    if (!is.null(asjson$error$id)) {
      response <-
        list(
          "errorId" = asjson$error$id,
          "query" = url,
          "errorMessage" = asjson$error$msg
        )
      return (response)
    } else {
      error.id <- "OK"
    }
    
    response <- list()
    response["errorId"] <- error.id
    response["query"] <- url
    response["surfaceId"] <- as.integer(surfaceId)
    
    for (i in 1:length(asjson[["data"]])) {
      name <- names(asjson$data[i])
      asjson[["data"]][[i]]["cumsums"] <-
        list(cumsum(asjson[["data"]][[i]][["sums"]]))
      asjson[["data"]][[i]]["minutes"] <-
        list(seq(1, length(asjson[["data"]][[i]][2]$counts)))
      df <- data.frame(Reduce(rbind, asjson$data[i]))
      df <- df[, c("minutes", "counts", "sums", "cumsums")]
      assign(paste0("s", surfaceId, "_", name), df)
      response[[name]] <-
        assign(paste0("s", surfaceId, "_", name), df)
    }
    
    if (isTRUE(detail)) {
      df <- data.frame(time = unlist(asjson$times))
      df$point <- seq.int(nrow(df))
      # recode where no time returned - OTP uses code 2147483647
      df[df == 2147483647] <- NA
      df <- df[, c("point", "time")]
      response[["times"]] <- df
    }
    
    return(response)
    
    
  }
