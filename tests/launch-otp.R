
# Requires: Sys.setenv("OTP_ON_LOCALHOST" = TRUE)

if(identical(Sys.getenv("OTP_ON_LOCALHOST"), "TRUE")) {

setwd("c:/users/marcu/git-repos/otpr")  
  
# OTP server in analyst mode for surface testing
system(paste0("java -Xmx2G -jar ", getwd(), "/tests/otp/otp-1.5.jar --router otpr-test --graphs ", getwd(), "/tests/otp/graphs --server --port 9090 --securePort 9091 --analyst --pointSets ", getwd(), "/tests/otp/pointsets"), intern = FALSE, wait = FALSE)
Sys.sleep(5)
# standard OTP server
system(paste0("java -Xmx2G -jar ", getwd(), "/tests/otp/otp-1.5.jar --router otpr-test --graphs ", getwd(), "/tests/otp/graphs --server"), intern = FALSE, wait = FALSE)
Sys.sleep(5)
# v2 OTP server
system(paste0("C:/PROGRA~1/Java/jdk-11.0.6/bin/java\ -Xmx2G -jar ", getwd(), "/tests/otp/otp-2.0.jar --load ", getwd(), "/tests/otp/graphs/otpr-test-v2 --port 9190 --securePort 9191"), intern = FALSE, wait = FALSE)
}
