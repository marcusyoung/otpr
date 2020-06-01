
# Requires: Sys.setenv("OTP_ON_LOCALHOST" = TRUE)

if(identical(Sys.getenv("OTP_ON_LOCALHOST"), "TRUE")) {
system("java -Xmx2G -jar /otp/otp.jar --router otpr-test --graphs /otp/graphs --server", intern = FALSE, wait = FALSE)
Sys.sleep(5)
}
