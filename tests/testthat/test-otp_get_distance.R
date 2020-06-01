context("Test the otp_get_distance function")

if (identical(Sys.getenv("OTP_ON_LOCALHOST"), "TRUE")) {
  otpcon <- otp_connect()
  # setup test query results - amend for new graph build
  fromPlace <- c(50.70776, -1.29347)
  toPlace <- c(50.69407, -1.29561)
  car_distance <- 2246
  walk_distance <- 1807
  bicycle_distance <- 1897
}


skip_if_no_otp <- function() {
  if (!identical(Sys.getenv("OTP_ON_LOCALHOST"), "TRUE"))
    skip("Not running test as the environment variable OTP_ON_LOCALHOST is not set to TRUE")
}

test_that("CAR - a list of three objects is returned; errorId is OK, value is correct",
          {
            skip_if_no_otp()
            response <-
              otp_get_distance(otpcon,
                               fromPlace = fromPlace,
                               toPlace = toPlace,
                               mode = "CAR")
            expect_equal(length(response), 3)
            expect_equal(response$errorId, "OK")
            expect_equal(round(response$distance), car_distance)
          })

test_that("WALK - list of three objects is returned; errorId is OK, value is correct",
          {
            skip_if_no_otp()
            response <-
              otp_get_distance(otpcon,
                               fromPlace = fromPlace,
                               toPlace = toPlace,
                               mode = "WALK")
            expect_equal(length(response), 3)
            expect_equal(response$errorId, "OK")
            expect_equal(round(response$distance), walk_distance)
          })

test_that("BICYCLE - list of three objects is returned; errorId is OK, value is correct",
          {
            skip_if_no_otp()
            response <-
              otp_get_distance(otpcon,
                               fromPlace = fromPlace,
                               toPlace = toPlace,
                               mode = "BICYCLE")
            expect_equal(length(response), 3)
            expect_equal(response$errorId, "OK")
            expect_equal(round(response$distance), bicycle_distance)
          })

test_that("CAR - no trip found", {
  skip_if_no_otp()
  response <-
    otp_get_distance(
      otpcon,
      fromPlace = c(50.67101, -1.37260),
      toPlace = toPlace,
      mode = "CAR"
    )
  expect_equal(length(response), 3)
  expect_equal(response$errorId, 404)
  expect_equal(grepl("No trip found", response$errorMessage, fixed = TRUE),
               TRUE)
})
