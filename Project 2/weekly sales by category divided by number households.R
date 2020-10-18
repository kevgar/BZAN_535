rm(list=ls())
library(data.table)
library(dplyr)
library(bit64)

# Loading data
f <- '/Users/kjgardner/Dropbox/MSBA\ Program/Fall\ 2016/BZAN\ 535/Journey/transaction_data.csv'
transaction_data <- data.table(fread(f))
f <- '/Users/kjgardner/Dropbox/MSBA\ Program/Fall\ 2016/BZAN\ 535/Journey/product.csv'
product <- data.table(fread(f)) 
f <- '/Users/kjgardner/Dropbox/MSBA\ Program/Fall\ 2016/BZAN\ 535/Journey/hh_demographic.csv'
hh_demographic <- data.table(fread(f))

transaction_data <-  transaction_data %>% inner_join(product) %>% data.table() # join transaction and product

# exclude sales of gasoline
'%!in%' <- function(x,y)!('%in%'(x,y))
transaction_data <- transaction_data %>% .[DEPARTMENT %!in% c("KIOSK-GAS")]

#number of households each week
num_households <- transaction_data %>%
        group_by(WEEK_NO) %>%
        summarise(num_households = length(unique(household_key))) %>%
        data.table()

# total annual sales and number of trips
summary_table <- transaction_data %>% 
        group_by(WEEK_NO, DEPARTMENT) %>%
        summarise(SUM_SALES=sum(SALES_VALUE)) %>%
        data.table() %>% 
        inner_join(num_households) %>% 
        data.table() %>% 
        .[,SUM_SALES_PER_HH:=round(SUM_SALES/num_households,2)]

rm(num_households)

# # join demographic variables
# summary_table2 <- summary_table %>% inner_join(hh_demographic) %>% data.table() #%>% .[WEEK_NO>22]
# 
# summary_table2 %>% .[, income_level:=""] %>% 
#         .[INCOME_DESC %in% c("Under 15K"), income_level:="Under 15K"] %>%
#         .[INCOME_DESC %in% c("15-24K"), income_level:="15-24K"] %>%
#         .[INCOME_DESC %in% c("25-34K"), income_level:="25-34K"] %>%
#         .[INCOME_DESC %in% c("35-49K"), income_level:="35-49K"] %>%
#         .[INCOME_DESC %in% c("50-74K"), income_level:="50-74K"] %>%
#         .[INCOME_DESC %in% c("75-99K"), income_level:="75-99K"] %>%
#         .[INCOME_DESC %in% c("100-124K", "125-149K", "150-174K", "175-199K", "200-249K", "250K+"), income_level:="100K+"]# %>%
# #.[, INCOME_DESC:=NULL]# %>%
# #.[, KID_CATEGORY_DESC:=NULL] #%>%
# #.[, HOMEOWNER_DESC:=NULL]



names(summary_table)
table(summary_table$INCOME_DESC)
# table(summary_table4$income_level)
# table(summary_table4$AGE_DESC)
# table(summary_table4$MARITAL_STATUS_CODE)
# table(summary_table4$HOMEOWNER_DESC)
# table(summary_table4$HH_COMP_DESC)
table(summary_table3$HOUSEHOLD_SIZE_DESC)
# table(summary_table4$KID_CATEGORY_DESC)
# 
# diff_sales_per_week <- summary_table4$diff_sales_per_week; hist(diff_sales_per_week)
# diff_trips_per_week <- summary_table4$diff_trips_per_week; hist(diff_trips_per_week)
# diff_avg_basket <- summary_table4$diff_avg_basket; hist(diff_avg_basket)
# 


# # Writing to csv file
write.csv(x = summary_table2
          , file = '/Users/kjgardner/Dropbox/MSBA\ Program/Fall\ 2016/BZAN\ 535/Project\ 2/weekly_sum_sales_by_hh_department.csv'
          , row.names = FALSE)


