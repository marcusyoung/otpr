

context("Test the otp_connect function")

skip_if_no_otp <- function() {
  if(!identical(Sys.getenv("OTP_ON_LOCALHOST"), "TRUE"))
    skip("Not running test as the environment variable OTP_ON_LOCALHOST is not set to TRUE")
}

# the following tests require an OTPv1 instance at http://localhost:8080/otp with "default" router

test_that("default object is created and make_url method works correctly", {
  otpcon <- otp_connect()
  expect_s3_class(otpcon, "otpconnect")
  skip_if_no_otp()
  expect_match(make_url(otpcon)$router, "http://localhost:8080/otp/routers/default")
  expect_match(make_url(otpcon)$otp, "http://localhost:8080/otp")
})

test_that("correct message when /otp endpoint exists", {
  skip_if_no_otp()
  expect_message(otp_connect(), "http://localhost:8080/otp is running OTPv1")
})

test_that("correct error when /otp endpoint does not exist", {
  skip_if_no_otp()
  expect_error(otp_connect(hostname = "test"), "Unable to connect to OTP. Does http://test:8080/otp even exist?")
})

test_that("correct message when router exists", {
  skip_if_no_otp()
  expect_message(otp_connect(), "Router http://localhost:8080/otp/routers/default exists")
})

test_that("correct error when router does not exist", {
  skip_if_no_otp()
  expect_error(otp_connect(router = "test"), "Router http://localhost:8080/otp/routers/test does not exist")
})


