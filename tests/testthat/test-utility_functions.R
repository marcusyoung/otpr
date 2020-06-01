context("Test utility fuctions")

skip_if_no_otp <- function() {
  if(!identical(Sys.getenv("OTP_ON_LOCALHOST"), "TRUE"))
    skip("Not running test as the environment variable OTP_ON_LOCALHOST is not set to TRUE")
}


test_that("Check otp_is_date wrong data", {
  skip_if_no_otp()
  expect_false(otp_is_date("21-01-2020")) 
})

test_that("Check otp_is_date good data", {
  skip_if_no_otp()
  expect_true(otp_is_date("01-21-2020")) 
})


test_that("Check otp_is_time wrong data", {
  skip_if_no_otp()
  expect_false(otp_is_time("26:00:00")) 
})

test_that("Check otp_is_time good data", {
  skip_if_no_otp()
  expect_true(otp_is_time("12:15:00")) 
})

test_that("Check otp_vector_match wrong", {
  skip_if_no_otp()
  expect_false(otp_vector_match(c("a", "b", "c"), c("a", "a", "b"))) 
})

test_that("Check otp_vector_match correct", {
  skip_if_no_otp()
  expect_true(otp_vector_match(c("a", "b", "c"), c("a", "c", "b"))) 
})


test_that("Check otp_from_epoch correct", {
  skip_if_no_otp()
  expect_equal(otp_from_epoch(1591025175000, tz = "Europe/London"), as.POSIXct("2020-06-01 16:26:15 BST"))
})