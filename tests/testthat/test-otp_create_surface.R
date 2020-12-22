context("Test the otp_create_surface function")

if (identical(Sys.getenv("OTP_ON_LOCALHOST"), "TRUE")) {
  # connect to the OTP server in Analyst mode
  otpcon_analyst <- otp_connect(port = 9090)
  
  # setup test query results - amend for a new graph build
  fromPlace <- c(50.75840, -1.30291)
  date <- "06-01-2020"
  time <- "12:00:00"
  mode <- "TRANSIT"
  rasterPath <- "C:/temp"
  response_query <- paste("http://localhost:9090/otp/surfaces?fromPlace=", paste(fromPlace, collapse = ","), "&mode=TRANSIT,WALK&date=", date, "&time=", time, "&maxWalkDistance=800&walkReluctance=2&waitReluctance=1&transferPenalty=0&minTransferTime=600&arriveBy=FALSE&batch=TRUE", sep="")
}

skip_if_no_otp <- function() {
  if (!identical(Sys.getenv("OTP_ON_LOCALHOST"), "TRUE"))
    skip("Not running test as the environment variable OTP_ON_LOCALHOST is not set to TRUE")
}

test_that("Check for invalid mode", {
  skip_if_no_otp()
  error <-
    try(otp_create_surface(otpcon_analyst,
                           fromPlace = fromPlace,
                           mode = "FOO"),
        silent = TRUE)
  expect_equal(grepl("Mode must be one of:", error, fixed = TRUE), TRUE)
})


test_that("create surface - no raster download", {
  skip_if_no_otp()
  response <-
    otp_create_surface(
      otpcon_analyst,
      fromPlace = fromPlace,
      date = date,
      time = time,
      mode = "TRANSIT"
    )
  expect_named(
    response,
    c(
      "errorId",
      "query",
      "surfaceId",
      "surfaceRecord",
      "rasterDownload"
    )
  )
  expect_equal(length(response), 5)
  expect_equal(response$errorId, "OK")
  expect_equal(response$surfaceId, 0)
  expect_equal(response$rasterDownload, "Not requested")
})


test_that("create surface - with raster download", {
  skip_if_no_otp()
  response <-
    otp_create_surface(
      otpcon_analyst,
      fromPlace = fromPlace,
      date = date,
      time = time,
      mode = "TRANSIT",
      getRaster = TRUE,
      rasterPath = rasterPath
    )
  expect_named(
    response,
    c(
      "errorId",
      "query",
      "surfaceId",
      "surfaceRecord",
      "rasterDownload"
    )
  )
  expect_equal(length(response), 5)
  expect_equal(response$errorId, "OK")
  expect_equal(response$surfaceId, 1)
  expect_equal(response$rasterDownload, paste0(rasterPath, "/surface_1.tiff"))
  expect_equal(file.exists(paste0(rasterPath, "/surface_1.tiff")), TRUE)
})


test_that("Check all parameters are passed", {
  skip_if_no_otp()
response <-
  otp_create_surface(
    otpcon_analyst,
    fromPlace = fromPlace,
    date = date,
    time = time,
    mode = "TRANSIT",
    maxWalkDistance = 800,
    walkReluctance = 2,
    transferPenalty = 0,
    minTransferTime = 600
  )
expect_equal(response$query, response_query)
})








