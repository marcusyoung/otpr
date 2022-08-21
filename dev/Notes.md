Create logo:

```
library(hexSticker)
library(sysfonts)
font_add("Gill Sans Nova", regular = "C:/Windows/Fonts/GillSansNova.ttf")


imgurl <- "C:/Users/marcu/git-repos/otpr/inst/logo.png"
sticker(imgurl, package="otpr", p_size=150, s_x=1, s_y=.75, s_width=.6, p_color = "white",
        filename="inst/imgfile.png", dpi = 1000, p_family = "Gill Sans Nova", h_fill = "#2179BF", h_color = "black", url = "Query OpenTripPlanner in R", u_size = 21, u_color = "white", u_family = "Gill Sans Nova", h_size = 1.5, u_x = 0.98, u_y = 0.065)
```