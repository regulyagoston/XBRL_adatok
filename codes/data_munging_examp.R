######
# This is an example code to clean 10K data using XBRL data
#
# It assumes you have run 'collect_data_examp.R' with 10K setup
#



library(data.table)
library(tidyverse)

#####
# set the folder path
folder_path <- "/Users/areguly6/Library/CloudStorage/OneDrive-CorvinusUniversityofBudapest/Research/XBRL/"
data_in <- 'data/XBRL_raw'

df_out <- readRDS(paste0(folder_path,data_in,'xbrl_raw.RDS'))

####
# Note that the result is ALL the available filings to SEC
#   !!! You need to clean it as it contain many irrelevant information !!! 
#   There are multiple filings referring to the same 10-K, you should retain the last submitted (and accepted)
#   Also within each filing there are multiple values referring to different years. You should keep only the last and most updated value(s).
#   Firms do change their name/CIK number you should check `former` and `changed` to see if there were any predecessor 
#
# Notes:
#   - `ddate` gives you the filing date from the company
#   - period is the balance sheet date (closing date) OR fy is the fiscal year
#   - tag represent the name/categorization for the asset

# Not the most elegant to mix tidyverse with data.table -- may improve

# Filter out missing CIK, report period and tag
df_out2 <- df_out %>% 
  drop_na( cik, period, tag ) %>% 
  drop_na( value ) # Use this only if you are 100% sure that you are after numeric values only

# Get the last reported value for each CIK (firm) for each period for each tag types
# !!TAKES TIME!!!
# Notes: 
#   - if you use multiple type of reports (not only 10Ks), you shall group by form as well!
#   - if you use text data, you shall also be careful not to remove important infos!
df_out3 <- df_out2 %>% 
  group_by( cik, period, tag ) %>% # Group by CIK, reporting periods and tags
  slice_max( ddate, n = 1 ) %>%    # Get the largest submission date
  slice_max( accepted, n = 1 ) %>% # If multiple submission with same date, take the one that is accepted
  ungroup()

# The remaining are just pure duplicates based on cik, period and tag...
df_out4 <- df_out3 %>% distinct( cik, period, tag, .keep_all = T )


#####
# Tags
# - there are 'standard' and 'custom' tags
# - first you should consider only standard tags (custom == 0)
#   - see the taxonomy for the tags: https://xbrl.us/xbrl-taxonomy/2024-us-gaap/
#   - there is a nice searchable database -- https://xbrlview.fasb.org/yeti/resources/yeti-gwt/Yeti.jsp#tax~(id~174*v~10231)!net~(a~3474*l~832)!lang~(code~en-us)!rg~(rg~32*p~12)
#   - or a list here: https://xbrl.us/data-rule/dqc_0015-le/
# - You should be careful! Do not go too deep! First rather collect the main variables
#       E.g. total asset's standard tag name is 'Assets'
# - Check out the excel + paper + code I gave you!

df_out5 <- df_out4 %>% filter( custom == 0 )

# Check number of total assets
sum(df_out5$tag == 'Assets' )
sum(df_out5$tag == 'Intangibles' )

##
# What I recommend you to do is to create a panel data-table with:
#   - firm-period rows and each column should be an important variable such as total assets, total liabilities, etc.
#   - you may consider first with a simple firm --> resulting in a simple time series
#   - or pick a specific time period and see all the firms --> resulting in a simple cross-sectional data

# Simple example with recoding the variables
df_it <- df_out5 %>% 
  mutate( tag_std =
            case_match( tag, 
                        # If there is a one-to-one map
                        'Assets' ~ 'at',
                        'Cash' ~ 'ch',
                        # You will need to aggregate multiple tags to get the final value 
                        #   OR name it differently and add them up in wide-format
                        c('ShortTermInvestments',) ~ 'ivst'
            ),
          # If multiple tags can mean the same quantity and there is a clear order which to use first
          tag_std = if_else( tag ==  'PreconfirmationLiabilitiesAndStockholdersEquity', 'lt', 
                             if_else( tag == 'Liabilities', 'lt', tag ) )
  ) %>% 
  filter( tag_std %in% c('at','lt','ch','ivst') )

# Make sure uom (unit of measurement) is USD if using different type of values
df_it2 <- df_it %>% select(cik, period, tag_std, value ) %>%
  pivot_wider( id_cols = c('cik','period'),
               names_from = tag_std,
               values_from = value )

