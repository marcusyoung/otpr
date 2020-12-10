#' Evaluates an existing surface. Using a pointset from the specified CSV file,
#' the travel time to each point is obtained from the specified surface. Accessibility
#' indicators are then generated for one or more 'opportunity' columns in the pointset
#' file. For example, you may have the number of jobs available at each location, or
#' the number of hospital beds.
#'
#' Requires OTP to have been started with the --analyst switch and the --pointset
#' parameter set to the path of a directory containing the pointset file(s).
#'
#' @param otpcon An OTP connection object produced by \code{\link{otp_connect}}.
#' @param surfaceId Integer, The id number of an existing surface for an origin
#' created using \code{otp_create_surface()}.
#' @param pointset Character string, the name of a pointset known to OTP. A pointset
#' is contained in a CSV file located in the pointset directory passed to OTP at startup.
#' The name of the pointset is the name of the file.
#' @param detail logical, whether the travel time to each location in the pointset
#' should be returned. Default is FALSE.
#' @return Returns ....
#' @examples \dontrun{
#'
#'}
#' @export
otp_evaluate_surface <-
  function(otpcon,
           surfaceId,
           pointset,
           detail = FALSE)
  {
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
      stop("Unable to connect to OTP. Does ",
           make_url(otpcon)$otp,
           " even exist?")
    } else if (req$status_code != 200) {
      stop(
        "Unable to find surface id: ",
        surfaceId,
        ". Is the id correct?
           Has a surface been created using otp_create_surface()?"
      )
    }
    
    
    # check for pointset
    req <-
      try(httr::GET(paste0(make_url(otpcon)$otp, "/pointsets/", pointset)), silent = T)
    if (class(req) == "try-error") {
      stop("Unable to connect to OTP. Does ",
           make_url(otpcon)$otp,
           " even exist?")
    } else if (req$status_code != 200) {
      stop(
        "Unable to find pointset: ",
        pointset,
        ". Is the name correct?
           Was a CSV file with this name located in the pointset directory
          when OTP was launched?"
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
    
    response <- list()
    response["errorId"] <- error.id
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
      df[df == 2147483647] <- NA
      df <- df[, c("point", "time")]
      response[["times"]] <- df
    }
    
    return(response)
    
    
  }
