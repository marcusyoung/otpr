# Windows
if(identical(Sys.getenv("OTP_ON_LOCALHOST"), "TRUE")) {
system("taskkill /im java.exe /F" , intern = FALSE, wait = FALSE)
}
