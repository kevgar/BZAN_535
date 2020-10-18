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

# # only include households for which we have two years of data
# households <- transaction_data %>% group_by(household_key) %>% 
#         summarise(earliest_week=min(WEEK_NO), latest_week=max(WEEK_NO)) %>% 
#         data.table() %>% # .[earliest_week <= 12 & latest_week >= 90] %>% 
#         select(household_key); households <- households$household_key
# transaction_data <- transaction_data %>% .[household_key %in% households]

# exclude sales of gasoline
'%!in%' <- function(x,y)!('%in%'(x,y))
transaction_data <- transaction_data %>% .[DEPARTMENT %!in% c("KIOSK-GAS")]

# total annual sales and number of trips
summary_table <- transaction_data %>% 
        .[, YEAR_ONE := WEEK_NO < 51] %>% group_by(household_key, YEAR_ONE) %>% 
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
        .[, Y2_SALES_PER_WEEK:=SUM_SALES/51] %>%
        .[, Y2_TRIPS_PER_WEEK:=NUM_TRIPS/51] %>% 
        .[, Y2_AVG_BASKET:=AVG_BASKET_SIZE] %>% 
        select(household_key, Y2_SALES_PER_WEEK, Y2_TRIPS_PER_WEEK, Y2_AVG_BASKET)

y1 <- summary_table2 %>% 
        .[YEAR_ONE==TRUE] %>% 
        .[, Y1_SALES_PER_WEEK:=SUM_SALES/(51-EARLIEST_WEEK)] %>%
        .[, Y1_TRIPS_PER_WEEK:=NUM_TRIPS/(51-EARLIEST_WEEK)] %>% 
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
        .[, spending_more:=Y2_SALES_PER_WEEK-Y1_SALES_PER_WEEK > 0]

#------------------------------------------------------------------------------------------------
## weekly number of purchases per hh by department (households that are spending less)
HH_DECREASING <- summary_table3 %>% .[spending_more == FALSE, household_key]
transaction_subset <- transaction_data %>% .[household_key %in% HH_DECREASING]
# number of households by week
num_households <- transaction_subset %>% group_by(WEEK_NO) %>% 
        summarise(num_households = length(unique(household_key))) %>% data.table()
# agregating the data
summary_table_1 <- transaction_subset %>% group_by(WEEK_NO, DEPARTMENT) %>%
        summarise(SUM_SALES=sum(SALES_VALUE), NUM_PURCHASES=n()) %>%
        data.table() %>% inner_join(num_households) %>% 
        data.table() %>% .[,SUM_SALES_PER_HH:=round(SUM_SALES/num_households,2)] %>%
        .[,PURCHASES_PER_HH:=round(NUM_PURCHASES/num_households,2)] %>% .[DEPARTMENT %!in% c("")]
#------------------------------------------------------------------------------------------------
## weekly number of purchases per hh by department (households that are spending more)
HH_INCREASING <- summary_table3 %>% .[spending_more == TRUE, household_key]
transaction_subset <- transaction_data %>% .[household_key %in% HH_INCREASING]
# number of households by week
num_households <- transaction_subset %>% group_by(WEEK_NO) %>% 
        summarise(num_households = length(unique(household_key))) %>% data.table()
# agregating the data
summary_table_2 <- transaction_subset %>% group_by(WEEK_NO, DEPARTMENT) %>%
        summarise(SUM_SALES=sum(SALES_VALUE), NUM_PURCHASES=n()) %>%
        data.table() %>% inner_join(num_households) %>% 
        data.table() %>% .[,SUM_SALES_PER_HH:=round(SUM_SALES/num_households,2)] %>%
        .[,PURCHASES_PER_HH:=round(NUM_PURCHASES/num_households,2)] %>% .[DEPARTMENT %!in% c("")]
#------------------------------------------------------------------------------------------------
rm(summary_table3)

#------------------------------------------------------------------------------------------------

# ####  top 15 departments by avg weekly sales per hh ####
# avg_sales_per_hh <- transaction_data %>% 
#         group_by(DEPARTMENT,WEEK_NO) %>%
#         summarise(AVG_SALES=mean(SALES_VALUE)) %>%
#         data.table() %>% inner_join(num_households) %>% 
#         data.table() %>% 
#         .[,AVG_SALES_PER_HH:=round(mean(AVG_SALES/num_households),2)] %>%
#         .[DEPARTMENT %!in% c("")] %>%
#         arrange(-SUM_SALES) %>% head(15)
# 
# ####  top 15 departments by avg weekly purchases per hh ####
# avg_purchases_per_hh <- transaction_data %>% 
#         group_by(DEPARTMENT,WEEK_NO) %>%
#         summarise(AVG_PURCHASES=n()) %>%
#         data.table() %>% inner_join(num_households) %>% 
#         data.table() %>% 
#         .[,AVG_PURCHASES_PER_HH:=round(mean(AVG_PURCHASES/num_households),2)] %>%
#         .[DEPARTMENT %!in% c("")] %>%
#         arrange(-SUM_SALES) %>% head(15)
#
# rm(num_households)

#------------------------------------------------------------------------------------------------
####  top 10 departments by avg weekly sales per hh ####
TOP_SALES <- transaction_data %>% 
        group_by(DEPARTMENT) %>%
        summarise(SUM_SALES=sum(SALES_VALUE)) %>%
        data.table() %>% .[DEPARTMENT %!in% c("")] %>%
        arrange(-SUM_SALES) %>% head(15)

####  top 10 departments by avg weekly purchases per hh ####
TOP_PURCHASES <- transaction_data %>% 
        group_by(DEPARTMENT) %>%
        summarise(NUM_PURCHASES=n()) %>%
        data.table() %>% .[DEPARTMENT %!in% c("")] %>%
        arrange(-NUM_PURCHASES) %>% head(15)

dataOUT <- summary_table_1[DEPARTMENT %in% TOP_SALES$DEPARTMENT]
#dataOUT <- summary_table_2[DEPARTMENT %in% TOP_SALES$DEPARTMENT]

unique(dataOUT$household_key)

# # Writing to csv file
# write.csv(x = dataOUT
#             , file = '/Users/kjgardner/Dropbox/MSBA\ Program/Fall\ 2016/BZAN\ 535/Project\ 2/DEPARTMENT_ENGAGEMENT_INCREASING.csv'
#             , row.names = FALSE)


