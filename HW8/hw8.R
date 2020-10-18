library(data.table)
library(dplyr)
library(bit64)

pancake_trans <- data.table(fread("/Users/kjgardner/Dropbox/MSBA\ Program/Fall\ 2016/BZAN\ 535/HW8/hw8.csv"))
  
summary_table <-
        DT_HW8 %>%
        group_by(week, upc) %>%
        summarise(median_unit_price=median(dollar_sales/units),sum_units=sum(units))

# Writing to csv file
write.csv(x = summary_table
          , file = '/Users/kjgardner/Dropbox/MSBA\ Program/Fall\ 2016/BZAN\ 535/HW8/question2.csv'
          , row.names = FALSE)
