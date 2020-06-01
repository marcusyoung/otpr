context("Test the otp_get_times function")

if (identical(Sys.getenv("OTP_ON_LOCALHOST"), "TRUE")) {
  otpcon <- otp_connect()
  
  # setup test query results - amend for a new graph build
  fromPlace <- c(50.75840, -1.30291)
  toPlace <- c(50.59871, -1.19133)
  transit_duration <- 94.32
  date <- "06-01-2020"
  time <- "12:00:00"
  legs_number <- 5
  arriveBy_time <- as.POSIXct("2020-06-01 11:52:50 BST")
  response_query <- paste("http://localhost:8080/otp/routers/default/plan?fromPlace=", paste(fromPlace, collapse = ","), "&toPlace=", paste(toPlace, collapse = ","), "&mode=TRANSIT,WALK&date=", date, "&time=", time, "&maxWalkDistance=800&walkReluctance=2&arriveBy=FALSE&transferPenalty=0&minTransferTime=600", sep="")
}

skip_if_no_otp <- function() {
  if (!identical(Sys.getenv("OTP_ON_LOCALHOST"), "TRUE"))
    skip("Not running test as the environment variable OTP_ON_LOCALHOST is not set to TRUE")
}

test_that("Check for invalid mode", {
  skip_if_no_otp()
  error <-
    try(otp_get_times(otpcon,
                      fromPlace = fromPlace,
                      toPlace = toPlace,
                      mode = "FOO"),
        silent = TRUE)
  expect_equal(grepl("Mode must be one of:", error, fixed = TRUE), TRUE)
})

test_that("Check no detail", {
  skip_if_no_otp()
  response <-
    otp_get_times(
      otpcon,
      fromPlace = fromPlace,
      toPlace = toPlace,
      date = date,
      time = time,
      mode = "TRANSIT"
    )
  expect_equal(length(response), 3)
  expect_equal(response$errorId, "OK")
  expect_equal(round(response$duration, 2), transit_duration)
})

test_that("Check with detail", {
  skip_if_no_otp()
  response <-
    otp_get_times(
      otpcon,
      fromPlace = fromPlace,
      toPlace = toPlace,
      date = date,
      time = time,
      mode = "TRANSIT",
      detail = TRUE
    )
  expect_equal(length(response), 3)
  expect_equal(response$errorId, "OK")
  expect_s3_class(response$itineraries, "data.frame")
  expect_named(
    response$itineraries,
    c(
      "start",
      "end",
      "timeZone",
      "duration",
      "walkTime",
      "transitTime",
      "waitingTime",
      "transfers"
    )
  )
  expect_equal(round(response$itineraries$duration, 2), transit_duration)
})

test_that("Check with legs", {
  skip_if_no_otp()
  response <-
    otp_get_times(
      otpcon,
      fromPlace = fromPlace,
      toPlace = toPlace,
      date = date,
      time = time,
      mode = "TRANSIT",
      detail = TRUE,
      includeLegs = TRUE
    )
  expect_equal(length(response), 4)
  expect_equal(response$errorId, "OK")
  expect_s3_class(response$legs, "data.frame")
  expect_equal(nrow(response$legs), legs_number)
  expect_named(
    response$itineraries,
    c(
      "start",
      "end",
      "timeZone",
      "duration",
      "walkTime",
      "transitTime",
      "waitingTime",
      "transfers"
    )
  )
  expect_equal(round(response$itineraries$duration, 2), transit_duration)
})

test_that("Check arriveby", {
  skip_if_no_otp()
  response <-
    otp_get_times(
      otpcon,
      fromPlace = fromPlace,
      toPlace = toPlace,
      date = date,
      time = time,
      mode = "TRANSIT",
      detail = TRUE,
      includeLegs = TRUE,
      arriveBy =  TRUE
    )
  expect_equal(response$itineraries$end, arriveBy_time)
})

test_that("All parameters are passed in query", {
  skip_if_no_otp
  response <-
    otp_get_times(
      otpcon,
      fromPlace = fromPlace,
      toPlace = toPlace,
      date = date,
      time = time,
      mode = "TRANSIT",
      maxWalkDistance = 800,
      walkReluctance = 2,
      arriveBy = FALSE,
      transferPenalty = 0,
      minTransferTime = 600,
      detail = TRUE,
      includeLegs = TRUE
    )
  expect_equal(response$query, response_query)
})
