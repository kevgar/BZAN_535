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

# only include households for which we have two years of data
households <- transaction_data %>% group_by(household_key) %>% 
        summarise(earliest_week=min(WEEK_NO), latest_week=max(WEEK_NO)) %>% 
        data.table() %>% # .[earliest_week <= 12 & latest_week >= 90] %>% 
        select(household_key); households <- households$household_key
transaction_data <- transaction_data %>% .[household_key %in% households]

# exclude sales of gasoline
'%!in%' <- function(x,y)!('%in%'(x,y))
transaction_data <- transaction_data %>% .[DEPARTMENT %!in% c("KIOSK-GAS")]

# total annual sales and number of trips
summary_table <- transaction_data %>% 
        .[, YEAR_ONE := WEEK_NO < 52] %>% group_by(household_key, YEAR_ONE) %>% 
        summarise(SUM_SALES=sum(SALES_VALUE), NUM_TRIPS = length(unique(BASKET_ID))) %>% 
        data.table()

earliest_week <- transaction_data %>% 
        group_by(household_key) %>% 
        summarise(EARLIEST_WEEK = min(WEEK_NO)) %>% 
        data.table()

avg_basket <- transaction_data %>%
        group_by(household_key, YEAR_ONE, BASKET_ID) %>%
        summarise(BASKET_SIZE=sum(SALES_VALUE)) %>%
        data.table() %>%
        group_by(household_key, YEAR_ONE) %>%
        summarise(AVG_BASKET_SIZE=mean(BASKET_SIZE)) %>%
        data.table() %>% 
        select(household_key, YEAR_ONE, AVG_BASKET_SIZE)

summary_table2 <- summary_table %>%
        inner_join(avg_basket) %>% 
        inner_join(earliest_week) %>% 
        data.table()

rm(earliest_week); rm(summary_table); rm(avg_basket)

# split by year
y2 <- summary_table2 %>% 
        .[YEAR_ONE==FALSE] %>% 
        .[, Y2_SALES_PER_WEEK:=SUM_SALES/52] %>%
        .[, Y2_TRIPS_PER_WEEK:=NUM_TRIPS/52] %>% 
        .[, Y2_AVG_BASKET:=AVG_BASKET_SIZE] %>% 
        select(household_key, Y2_SALES_PER_WEEK, Y2_TRIPS_PER_WEEK, Y2_AVG_BASKET)

y1 <- summary_table2 %>% 
        .[YEAR_ONE==TRUE] %>% 
        .[, Y1_SALES_PER_WEEK:=SUM_SALES/(52-EARLIEST_WEEK)] %>%
        .[, Y1_TRIPS_PER_WEEK:=NUM_TRIPS/(52-EARLIEST_WEEK)] %>% 
        .[, Y1_AVG_BASKET:=AVG_BASKET_SIZE] %>% 
        select(household_key, Y1_SALES_PER_WEEK, Y1_TRIPS_PER_WEEK, Y1_AVG_BASKET)

rm(summary_table2)

# rejoin by household_key
summary_table3 <- y2 %>% inner_join(y1) %>% data.table()

rm(y1); rm(y2) 
# compute difference and percent change in sales by household
summary_table3 %>% 
        .[, diff_sales_per_week:=round(Y2_SALES_PER_WEEK-Y1_SALES_PER_WEEK,2)] %>%
        .[, diff_trips_per_week:=Y2_TRIPS_PER_WEEK-Y1_TRIPS_PER_WEEK] %>%
        .[, diff_avg_basket:=round(Y2_AVG_BASKET-Y1_AVG_BASKET,2)] %>%
        .[, spending_more:=Y2_SALES_PER_WEEK-Y1_SALES_PER_WEEK > 0] %>%
        .[, logratio_sales:=log(Y2_SALES_PER_WEEK/Y1_SALES_PER_WEEK)] %>%
        .[, logratio_trips:=log(Y2_TRIPS_PER_WEEK/Y1_TRIPS_PER_WEEK)] %>%
        .[, logratio_basket:=log(Y2_AVG_BASKET/Y1_AVG_BASKET)]
        
        
# join demographic variables
summary_table4 <- summary_table3 %>% inner_join(hh_demographic) %>% data.table()

rm(summary_table3)
summary_table4 %>% .[, income_level:=""] %>% 
        .[INCOME_DESC %in% c("Under 15K"), income_level:="Under 15K"] %>%
        .[INCOME_DESC %in% c("15-24K"), income_level:="15-24K"] %>%
        .[INCOME_DESC %in% c("25-34K"), income_level:="25-34K"] %>%
        .[INCOME_DESC %in% c("35-49K"), income_level:="35-49K"] %>%
        .[INCOME_DESC %in% c("50-74K"), income_level:="50-74K"] %>%
        .[INCOME_DESC %in% c("75-99K"), income_level:="75-99K"] %>%
        .[INCOME_DESC %in% c("100-124K", "125-149K", "150-174K", "175-199K", "200-249K", "250K+"), income_level:="100K+"]# %>%
        #.[, INCOME_DESC:=NULL]# %>%
        #.[, KID_CATEGORY_DESC:=NULL] #%>%
        #.[, HOMEOWNER_DESC:=NULL]


# names(summary_table4)
# table(summary_table4$INCOME_DESC)
# table(summary_table4$income_level)
# table(summary_table4$AGE_DESC)
# table(summary_table4$MARITAL_STATUS_CODE)
# table(summary_table4$HOMEOWNER_DESC)
# table(summary_table4$HH_COMP_DESC)
# table(summary_table4$HOUSEHOLD_SIZE_DESC)
# table(summary_table4$KID_CATEGORY_DESC)

# Writing to csv file
write.csv(x = summary_table4
           , file = '/Users/kjgardner/Dropbox/MSBA\ Program/Fall\ 2016/BZAN\ 535/Project\ 2/project2_question1.csv'
           , row.names = FALSE)

