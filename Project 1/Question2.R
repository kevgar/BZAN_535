
rm(list=ls())
library(data.table)
library(dplyr)
library(bit64)

# Loading data
f <- '/Users/kjgardner/Dropbox/MSBA\ Program/Fall\ 2016/BZAN\ 535/Journey/transaction_data.csv'
transaction_data <- data.table(fread(f))
f <- '/Users/kjgardner/Dropbox/MSBA\ Program/Fall\ 2016/BZAN\ 535/Journey/product.csv'
product <- data.table(fread(f))

## Cleaning the product data

# Only keep rows with COMMODITY_DESC=='SOFT DRINKS'
product_subset <- product[COMMODITY_DESC=='SOFT DRINKS']

# Cleaning SUB_COMMODITY_DES column
product_subset %>%
        .[, SUB_COMMODITY_DESC:=gsub('SOFT DRINKS ', '', SUB_COMMODITY_DESC)] %>%
        .[, SUB_COMMODITY_DESC:=gsub('SFT DRNK ', '', SUB_COMMODITY_DESC)] %>%
        .[, SUB_COMMODITY_DESC:=gsub('SOFT DRINK ', '', SUB_COMMODITY_DESC)]

# wordlist <- unique(
#         product_subset[SUB_COMMODITY_DESC=='12/18&15PK CAN CAR' 
#                        & CURR_SIZE_OF_PRODUCT!='12 OZ' 
#                        & CURR_SIZE_OF_PRODUCT!='2 LTR']
#         )
# unique(wordlist$CURR_SIZE_OF_PRODUCT)

categories_12_OZ <- c("12/12 OZ"
                      , "@    12 OZ"
                      , "12 PK"
                      , "144 OZ"
                      , "144 PK"
                      , "12-12 OZ"
                      , "12PK/12OZ"
                      , "0000012 OZ"
                      , "12PK/12 OZ"
                      , "12OZ/12PK"
                      , "12PK 12 OZ"
                      , "12OZ 12PK"
                      , "12OZ CAN"
                      , "144OZ/12PK"
                      , "12PK"
                      , "12PK/12 0Z"
                      , "144 OUNCE"
                      , "12/12OZ CN"
                      , "12PK FM")

# Cleaning CURR_SIZE_OF_PRODUCT column for 12/18 packs of 12 oz. cans
product_subset[CURR_SIZE_OF_PRODUCT %in% categories_12_OZ, CURR_SIZE_OF_PRODUCT:='12 OZ']

# # Cleaning CURR_SIZE_OF_PRODUCT column for 2 LTR
# 
# wordlist <- unique(
#         product_subset[SUB_COMMODITY_DESC=='2 LITER BTL CARB INCL'
#                        |SUB_COMMODITY_DESC=='BOTTLE NON-CARB (EX'
#                        |SUB_COMMODITY_DESC=='MIXERS(TONIC WTR/CLUB SODA/GNG'
#                        |SUB_COMMODITY_DESC=="MLT-PK BTL CARB (EXCP"
#                        & CURR_SIZE_OF_PRODUCT!='12 OZ']
#         )
# unique(wordlist$CURR_SIZE_OF_PRODUCT)
# 
# categories_2_LTR <- c("2LTR"
#   , "67.6 OZ"
#   , "2 LITER"
#   , "67.6  OZ"
#   , "67.7 OZ"
#   , "2 LTR*"
#   , "*    2 LTR"
#   , "2LITER"
#   , "67.6OZ"
#   , "2LTR BTL"
#   , "2 LTR PET")
# 
# # Cleaning CURR_SIZE_OF_PRODUCT column for 2 LTR
# product_subset[CURR_SIZE_OF_PRODUCT %in% categories_2_LTR, CURR_SIZE_OF_PRODUCT:='2 LTR']

# Joining transaction_data with product_subset
myJoin <- transaction_data %>%
         left_join(product_subset) %>%
         data.table()

# Select rows where COMMODITY_DESC=='SOFT DRINKS'
soft_drinks <- myJoin[COMMODITY_DESC=='SOFT DRINKS'] %>%
        # Select rows where SUB_COMMODITY_DESC=='12/18&15PK CAN CAR'
        .[SUB_COMMODITY_DESC=='12/18&15PK CAN CAR'] %>%
        # Select rows where CURR_SIZE_OF_PRODUCT=='12 OZ'
        .[CURR_SIZE_OF_PRODUCT=='12 OZ']# %>%
        # # Select rows where MANUFACTURER is ..
        # .[MANUFACTURER %in% c(69, 103, 1208, 2224)]


# # Compute market share and average volume of each manufacturer
# total_market <- sum(soft_drinks$SALES_VALUE)
# summary_table <- 
#         soft_drinks %>% group_by(MANUFACTURER) %>% 
#         summarise(MARKET_SHARE=sum(SALES_VALUE)/total_market
#         , AVG_VOLUME=mean(SALES_VALUE)) %>%
#         data.table()
# 
# # Formatting dollars
# dollars <- function(x, digits = 2, format = "f", ...) {
#         paste0("$", formatC(x, format = format, digits = digits, ...))
# }
# # Formatting percentages
# percent <- function(x, digits = 2, format = "f", ...) {
#         paste0(formatC(100 * x, format = format, digits = digits, ...), "%")
# }
# summary_table[, MANUFACTURER:=as.character(MANUFACTURER)]
# summary_table[, MARKET_SHARE:=percent(MARKET_SHARE)]
# summary_table[, AVG_VOLUME:=dollars(AVG_VOLUME)]


# Compute average number of days per week with discount sales for each manufacturer

soft_drinks[, DISCOUNT_STATUS:= (RETAIL_DISC < 0)]
soft_drinks[, UNIT_PRICE:=SALES_VALUE/QUANTITY]

discount_frequency <- # Check if discounted for each day
        soft_drinks %>% group_by(WEEK_NO, DAY, MANUFACTURER) %>% 
        summarise(DAYS_WITH_DISCOUNT= max(DISCOUNT_STATUS)) %>%
        data.table()

weekly_discount_frequency <- 
        discount_frequency  %>% group_by(WEEK_NO, MANUFACTURER) %>% 
        summarise(DAYS_WITH_DISCOUNT=sum(DAYS_WITH_DISCOUNT))

weekly_total_market <- 
        soft_drinks %>% group_by(WEEK_NO) %>% 
        summarise(TOTAL_MARKET=sum(SALES_VALUE))

weekly_avg_price <- 
        soft_drinks %>% group_by(WEEK_NO, MANUFACTURER) %>% 
        summarise(AVG_UNIT_PRICE = round(mean(SALES_VALUE),2))

weekly_sales <- 
        soft_drinks %>% group_by(WEEK_NO, MANUFACTURER) %>%
        summarise(WEEKLY_SALES_VALUE = sum(SALES_VALUE))

weekly_market_share <- 
        weekly_sales %>% 
        left_join(weekly_total_market) %>%
        data.table() %>%
        mutate(WEEKLY_MARKET_SHARE=round((WEEKLY_SALES_VALUE/TOTAL_MARKET)*100,2))
        
# Putting it all back together

summary_table <-
        weekly_market_share %>% 
        left_join(weekly_discount_frequency) %>%
        left_join(weekly_avg_price) %>%
        filter(MANUFACTURER %in% c(69, 103, 1208, 2224))


# Writing to csv file
 write.csv(x = summary_table
           , file = '/Users/kjgardner/Dropbox/MSBA\ Program/Fall\ 2016/BZAN\ 535/Project\ 1/project1_question2_weekly.csv'
           , row.names = FALSE)
