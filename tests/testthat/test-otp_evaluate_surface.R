context("Test the otp_evaluate_surface function")

if (identical(Sys.getenv("OTP_ON_LOCALHOST"), "TRUE")) {
  # connect to the OTP server in Analyst mode
  otpcon_analyst <- otp_connect(port = 9090)
  
  # setup test query results - amend for a new graph build
  surfaceId <- 0
  pointset <- "jobs"
  response_query <- NULL
}

skip_if_no_otp <- function() {
  if (!identical(Sys.getenv("OTP_ON_LOCALHOST"), "TRUE"))
    skip("Not running test as the environment variable OTP_ON_LOCALHOST is not set to TRUE")
}


# Test that function not available for OTPv2


# test for surfaces end point


test_that("Check for invalid surfaceId", {
  skip_if_no_otp()
  error <-
    try(otp_evaluate_surface(otpcon_analyst,
                      surfaceId = 6,
                      pointset = pointset),
        silent = TRUE)
  expect_equal(grepl("Unable to find surface id: 6", error, fixed = TRUE), TRUE)
})

test_that("Check for invalid pointset", {
  skip_if_no_otp()
  error <-
    try(otp_evaluate_surface(otpcon_analyst,
                             surfaceId = surfaceId,
                             pointset = "FOO"),
        silent = TRUE)
  expect_equal(grepl("Unable to find pointset: FOO.", error, fixed = TRUE), TRUE)
})

test_that("Check for valid response", {
  skip_if_no_otp()
  response <- otp_evaluate_surface(otpcon_analyst, surfaceId = surfaceId, pointset = pointset, detail = TRUE)
  expect_equal(length(response), 5)
  expect_equal(response$errorId, "OK")
  expect_equal(response$surfaceId, 0)
  expect_s3_class(response$population, "data.frame")
  expect_s3_class(response$times, "data.frame")
  expect_named(
    response$population,
    c(
      "minutes",
      "counts",
      "sums",
      "cumsums"
    )
  )
  expect_named(
    response$times,
    c(
      "point",
      "time"
    )
  )
  expect_equal(all(tail(response$population, n=1) == c(102, 1, 437, 52945)), TRUE)
  expect_equal(nrow(response$population), 102)
  expect_equal(nrow(response$times), 135)
  expect_equal(all(head(response$times, n=1) == c(1, 3158)), TRUE)
  expect_equal(mean(response$times$time, na.rm = TRUE), 3273.252)
})

test_that("Check when multiple indicators in pointset file", {
  skip_if_no_otp()
  response <- otp_evaluate_surface(otpcon_analyst, surfaceId = surfaceId, pointset = "test", detail = TRUE)
  expect_equal(length(response), 6)
  expect_equal(response$errorId, "OK")
  expect_equal(response$surfaceId, 0)
  expect_s3_class(response$indicator, "data.frame")
  expect_s3_class(response$population, "data.frame")
  expect_s3_class(response$times, "data.frame")
  expect_named(
    response$indicator,
    c(
      "minutes",
      "counts",
      "sums",
      "cumsums"
    )
  )
  expect_named(
    response$population,
    c(
      "minutes",
      "counts",
      "sums",
      "cumsums"
    )
  )
  expect_named(
    response$times,
    c(
      "point",
      "time"
    )
  )
  expect_equal(all(tail(response$population, n=1) == c(102, 1, 437, 52945)), TRUE)
  expect_equal(all(tail(response$indicator, n=1) == c(102, 1, 218, 26438)), TRUE)
  expect_equal(nrow(response$population), 102)
  expect_equal(nrow(response$indicator), 102)
  expect_equal(nrow(response$times), 135)
  expect_equal(all(head(response$times, n=1) == c(1, 3158)), TRUE)
  expect_equal(mean(response$times$time, na.rm = TRUE), 3273.252)
})




