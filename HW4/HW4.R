library(data.table)
library(ggvis)
library(dplyr)

# Question 1

dt1a <- data.table(read.csv('~/Dropbox/MSBA\ Program/Fall\ 2016/BZAN\ 535/HW4/q1_a.csv'))
dt1b <- data.table(read.csv('~/Dropbox/MSBA\ Program/Fall\ 2016/BZAN\ 535/HW4/q1_b.csv'))
dt1c <- dt1a[, in.catalog.interior:= week %in% dt1b$week]


add_title <- function(vis, ..., x_lab = "X units", title = "Plot Title")
        
        

dt1c %>% ggvis(~week, ~total_units,fill=~as.numeric(in.catalog.interior)) %>% 
        layer_points() %>%
        layer_smooths() %>%
        hide_legend('fill')
        

# Question 2



