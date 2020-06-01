context("Test the otp_get_isochrone function")

if (identical(Sys.getenv("OTP_ON_LOCALHOST"), "TRUE")) {
  otpcon <- otp_connect()
  
  # setup test query results - amend for a new graph build
  location <- c(50.75872, -1.28943)
  toPlace <- c(50.75872, -1.28943)
  date <- "06-01-2020"
  time <- "06:00:00"
  cutoffs <- c(300, 600, 900, 1200)
  response_query <-
    paste(
      "http://localhost:8080/otp/routers/default/isochrone?toPlace=",
      paste(toPlace, collapse = ","),
      "&fromPlace=",
      paste(location, collapse = ","),
      "&mode=TRANSIT,WALK&batch=TRUE&date=",
      date,
      "&time=",
      time,
      "&maxWalkDistance=800&walkReluctance=2&arriveBy=FALSE&transferPenalty=0&minTransferTime=600&cutoffSec=",
      paste(cutoffs, collapse = "&cutoffSec="),
      sep = ""
    )
}

skip_if_no_otp <- function() {
  if (!identical(Sys.getenv("OTP_ON_LOCALHOST"), "TRUE"))
    skip("Not running test as the environment variable OTP_ON_LOCALHOST is not set to TRUE")
}

test_that("Error when using OTPv2", {
  skip_if_no_otp()
  otpcon2 <- otpcon
  otpcon2$version <- 2
  expect_error(otp_get_isochrone(
    otpcon2,
    location = location,
    date = date,
    time = time,
    mode = "TRANSIT",
    cutoffs = cutoffs
  ), "OTP server is running OTPv2. otp_get_isochrone() is only supported in OTPv1", fixed = TRUE)
})

test_that("query geojson format from location", {
  skip_if_no_otp()
  response <-
    otp_get_isochrone(
      otpcon,
      location = location,
      date = date,
      time = time,
      mode = "TRANSIT",
      cutoffs = cutoffs
    )
  expect_equal(response$errorId, "OK")
  expect_true(grepl("\"type\":\"FeatureCollection\"", response$response))
})

test_that("query SF format from location", {
  skip_if_no_otp()
  response <-
    otp_get_isochrone(
      otpcon,
      location = location,
      date = date,
      time = time,
      mode = "TRANSIT",
      cutoffs = cutoffs,
      format = "SF"
    )
  expect_equal(response$errorId, "OK")
  expect_s3_class(response$response[1], "sf")
})

test_that("query geojson format TO location", {
  skip_if_no_otp()
  response <-
    otp_get_isochrone(
      otpcon,
      location = location,
      fromLocation = FALSE,
      date = date,
      time = time,
      mode = "TRANSIT",
      cutoffs = cutoffs
    )
  expect_equal(response$errorId, "OK")
  expect_true(grepl("\"type\":\"FeatureCollection\"", response$response))
  expect_true(grepl("toPlace=", response$query))
})

test_that("all parameters are passed in query", {
  skip_if_no_otp()
  response <-
    otp_get_isochrone(
      otpcon,
      location,
      fromLocation = FALSE,
      date = date,
      time = time,
      mode = "TRANSIT",
      cutoffs = cutoffs,
      maxWalkDistance = 800,
      walkReluctance = 2,
      arriveBy = FALSE,
      transferPenalty = 0,
      minTransferTime = 600,
      format = "JSON",
      batch = TRUE
    )
  expect_equal(response$query, response_query)
})