rm(list=ls())
library(data.table)
library(dplyr)
library(bit64)

# Loading data
f <- '/Users/kjgardner/Dropbox/MSBA\ Program/Fall\ 2016/BZAN\ 535/Journey/transaction_data.csv'
transaction_data <- data.table(fread(f))





# Only keep rows with PRODUCT_ID==1053690
transaction_data_1053690 <- transaction_data[PRODUCT_ID==1053690]

# Create column for price per unit less than $1.59
transaction_data_1053690[, DISCOUNT_STATUS:=(RETAIL_DISC/QUANTITY < 0)] # TRUE/FALSE for discount status
transaction_data_1053690[, UNIT_DISCOUNT:=round(RETAIL_DISC/QUANTITY,2)] # Unit Retail discount
transaction_data_1053690[, UNIT_PRICE:=round(SALES_VALUE/QUANTITY, 2)]

# # For the graph on part question 1
# # Compute weekly average price, average discount amount, and sum quantity 
# transaction_data_1053690_weekly <- transaction_data_1053690 %>%
#         group_by(WEEK_NO, DISCOUNT_STATUS) %>%
#         summarise(AVG_UNIT_PRICE=round(mean(UNIT_PRICE),2)
#                   , AVG_UNIT_DISCOUNT=round(mean(UNIT_DISCOUNT),2)
#                   , SUM_QUANTITY=sum(QUANTITY)) %>%
#         data.table()

# For the other questions
# Compute weekly average price, average discount amount, and sum quantity 
transaction_data_1053690_weekly <- transaction_data_1053690 %>%
        group_by(WEEK_NO) %>%
        summarise(AVG_UNIT_PRICE=round(mean(UNIT_PRICE),2)
                  , AVG_UNIT_DISCOUNT=round(mean(UNIT_DISCOUNT),2)
                  , SUM_QUANTITY=sum(QUANTITY)) %>%
        data.table()


###########
transaction_data_844165 <- transaction_data[PRODUCT_ID==844165]

# Create column for price per unit less than $1.59
transaction_data_844165[, DISCOUNT_STATUS:=(RETAIL_DISC/QUANTITY < 0)] # TRUE/FALSE for discount status
transaction_data_844165[, UNIT_DISCOUNT:=round(RETAIL_DISC/QUANTITY,2)] # Unit Retail discount
transaction_data_844165[, UNIT_PRICE:=round(SALES_VALUE/QUANTITY, 2)]

# # For the graph on part question 1
# # Compute weekly average price, average discount amount, and sum quantity 
# transaction_data_844165_weekly <- transaction_data_844165 %>%
#         group_by(WEEK_NO, DISCOUNT_STATUS) %>%
#         summarise(AVG_UNIT_PRICE=round(mean(UNIT_PRICE),2)
#                   , AVG_UNIT_DISCOUNT=round(mean(UNIT_DISCOUNT),2)
#                   , SUM_QUANTITY=sum(QUANTITY)) %>%
#         data.table()

# For the other questions
# Compute weekly average price, average discount amount, and sum quantity 
transaction_data_844165_weekly <- transaction_data_844165 %>%
        group_by(WEEK_NO) %>%
        summarise(AVG_UNIT_PRICE=round(mean(UNIT_PRICE),2)
                  , AVG_UNIT_DISCOUNT=round(mean(UNIT_DISCOUNT),2)
                  , SUM_QUANTITY=sum(QUANTITY)) %>%
        data.table()



Bonus_data <- transaction_data_1053690_weekly %>% 
        # group_by(WEEK_NO)
        left_join(transaction_data_844165_weekly, by=c("WEEK_NO")) 


############



write.csv(x = Bonus_data
          , file = '/Users/kjgardner/Dropbox/MSBA\ Program/Fall\ 2016/BZAN\ 535/HW\ 7/Bonus_data.csv'
          , row.names = FALSE) #102 obs. of 4 variables
