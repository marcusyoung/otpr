context("Test the otp_get_times function")

if (identical(Sys.getenv("OTP_ON_LOCALHOST"), "TRUE")) {
  otpcon <- otp_connect()
  otpcon_v2 <- otp_connect(port = 9190)
  
  # setup test query results - amend for a new graph build
  fromPlace <- c(50.75840, -1.30291)
  toPlace <- c(50.59871, -1.19133)
  transit_duration <- 94.3
  date <- "06-01-2020"
  time <- "12:00:00"
  legs_number <- 5
  arriveBy_time <- as.POSIXct("2020-06-01 11:53:00 BST")
  response_query <- paste("http://localhost:8080/otp/routers/default/plan?fromPlace=", paste(fromPlace, collapse = ","), "&toPlace=", paste(toPlace, collapse = ","), "&mode=TRANSIT,WALK&date=", date, "&time=", time, "&maxWalkDistance=1600&walkReluctance=4&waitReluctance=2&arriveBy=TRUE&transferPenalty=10&minTransferTime=600&optimize=TRANSFERS", sep="")
  response_query_otp2 <- paste("http://localhost:9190/otp/routers/default/plan?fromPlace=", paste(fromPlace, collapse = ","), "&toPlace=", paste(toPlace, collapse = ","), "&mode=TRANSIT,WALK&date=", date, "&time=", time, "&maxWalkDistance=1600&walkReluctance=4&waitReluctance=2&arriveBy=TRUE&transferPenalty=10&minTransferTime=600&optimize=TRANSFERS", sep="")
}

skip_if_no_otp <- function() {
  if (!identical(Sys.getenv("OTP_ON_LOCALHOST"), "TRUE"))
    skip("Not running test as the environment variable OTP_ON_LOCALHOST is not set to TRUE")
}

# OTP1

test_that("OTP1 Check for invalid mode", {
  skip_if_no_otp()
  error <-
    try(otp_get_times(otpcon,
                      fromPlace = fromPlace,
                      toPlace = toPlace,
                      mode = "FOO"),
        silent = TRUE)
  expect_equal(grepl("Mode must be one of:", error, fixed = TRUE), TRUE)
})

test_that("OTP1 basic query no detail", {
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
  expect_equal(round(response$duration, 1), transit_duration)
})

test_that("OTP1 query with detail", {
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
  expect_equal(round(response$itineraries$duration, 1), transit_duration)
})

test_that("OTP1 query with legs", {
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
  expect_equal(length(response), 3)
  expect_equal(response$errorId, "OK")
  expect_s3_class(response$itineraries$legs[[1]], "data.frame")
  expect_equal(nrow(response$itineraries$legs[[1]]), legs_number)
  expect_named(
    response$itineraries[1, ],
    c(
      "start",
      "end",
      "timeZone",
      "duration",
      "walkTime",
      "transitTime",
      "waitingTime",
      "transfers",
      "legs"
    )
  )
  expect_equal(round(response$itineraries[1, "duration"], 1), transit_duration)
})

test_that("OTP1 query with arriveby", {
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
  expect_equal(round(response$itineraries[1, "end"], "mins"), arriveBy_time)
})

test_that("OTP1 all parameters are passed in query", {
  skip_if_no_otp()
  response <-
    suppressWarnings(otp_get_times(
      otpcon,
      fromPlace = fromPlace,
      toPlace = toPlace,
      date = date,
      time = time,
      mode = "TRANSIT",
      maxWalkDistance = 1600,
      walkReluctance = 4,
      waitReluctance = 2,
      arriveBy = TRUE,
      transferPenalty = 10,
      minTransferTime = 600,
      detail = TRUE,
      includeLegs = TRUE,
      extra.params = list(optimize = "TRANSFERS")
    ))
  expect_equal(response$query, response_query)
})

test_that("OTP1 warning on use of extra.params", {
  skip_if_no_otp()
  expect_warning(otp_get_times(otpcon,
                               fromPlace = fromPlace,
                               toPlace = toPlace,
                               maxWalkDistance = 80000,
                               extra.params = list("FOO" = 1)), "Unknown parameters were passed to the OTP API without checks: FOO")
})

# OTP2

test_that("OTP2 Check for invalid mode", {
  skip_if_no_otp()
  error <-
    try(otp_get_times(otpcon_v2,
                      fromPlace = fromPlace,
                      toPlace = toPlace,
                      mode = "FOO"),
        silent = TRUE)
  expect_equal(grepl("Mode must be one of:", error, fixed = TRUE), TRUE)
})

test_that("OTP2 basic query no detail", {
  skip_if_no_otp()
  response <-
    otp_get_times(
      otpcon_v2,
      fromPlace = fromPlace,
      toPlace = toPlace,
      date = date,
      time = time,
      mode = "TRANSIT",
      maxWalkDistance = 800
    )
  expect_equal(length(response), 3)
  expect_equal(response$errorId, "OK")
  expect_equal(round(response$duration, 1), transit_duration)
})

test_that("OTP2 query with detail", {
  skip_if_no_otp()
  response <-
    otp_get_times(
      otpcon_v2,
      fromPlace = fromPlace,
      toPlace = toPlace,
      date = date,
      time = time,
      mode = "TRANSIT",
      detail = TRUE,
      maxWalkDistance = 800
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
  expect_equal(round(response$itineraries$duration, 1), transit_duration)
})

test_that("OTP2 query with legs", {
  skip_if_no_otp()
  response <-
    otp_get_times(
      otpcon_v2,
      fromPlace = fromPlace,
      toPlace = toPlace,
      date = date,
      time = time,
      mode = "TRANSIT",
      detail = TRUE,
      includeLegs = TRUE,
      maxWalkDistance = 800
    )
  expect_equal(length(response), 3)
  expect_equal(response$errorId, "OK")
  expect_s3_class(response$itineraries$legs[[1]], "data.frame")
  expect_equal(nrow(response$itineraries$legs[[1]]), legs_number)
  expect_named(
    response$itineraries[1, ],
    c(
      "start",
      "end",
      "timeZone",
      "duration",
      "walkTime",
      "transitTime",
      "waitingTime",
      "transfers",
      "legs"
    )
  )
  expect_equal(round(response$itineraries[1, "duration"], 1), transit_duration)
})

test_that("OTP2 query with arriveby", {
  skip_if_no_otp()
  response <-
    otp_get_times(
      otpcon_v2,
      fromPlace = fromPlace,
      toPlace = toPlace,
      date = date,
      time = time,
      mode = "TRANSIT",
      detail = TRUE,
      includeLegs = TRUE,
      arriveBy =  TRUE,
      maxWalkDistance = 800
    )
  expect_equal(round(response$itineraries[1, "end"], "mins"), arriveBy_time)
})

test_that("OTP2 all parameters are passed in query", {
  skip_if_no_otp()
  response <-
    suppressWarnings(otp_get_times(
      otpcon_v2,
      fromPlace = fromPlace,
      toPlace = toPlace,
      date = date,
      time = time,
      mode = "TRANSIT",
      maxWalkDistance = 1600,
      walkReluctance = 4,
      waitReluctance = 2,
      arriveBy = TRUE,
      transferPenalty = 10,
      minTransferTime = 600,
      detail = TRUE,
      includeLegs = TRUE,
      extra.params = list(optimize = "TRANSFERS")
    ))
  expect_equal(response$query, response_query_otp2)
})

test_that("OTP2 warning on use of extra.params", {
  skip_if_no_otp()
  expect_warning(otp_get_times(otpcon_v2,
                      fromPlace = fromPlace,
                      toPlace = toPlace,
                      maxWalkDistance = 0,
                      extra.params = list("FOO" = 1)), "Unknown parameters were passed to the OTP API without checks: FOO")
})

test_that("OTP2 empty itinerary is intercepted", {
  skip_if_no_otp()
  response <- otp_get_times(otpcon_v2,
                            fromPlace = fromPlace,
                            toPlace = toPlace,
                            maxWalkDistance = 800)
  expect_equal(response$errorId, -9999)
  expect_equal(grepl("No itinerary returned", response$errorMessage, fixed = TRUE), TRUE)
})
