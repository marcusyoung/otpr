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




