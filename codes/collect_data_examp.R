######
# This is an example code to collect data based onb different purposes, using
#   XBRL data
# This code assumes unzipped folders of XBRL data downloaded from:
#   https://www.sec.gov/dera/data/financial-statement-data-sets
#
#
# Go and check out: https://www.sec.gov/ixviewer/ix.html?doc=/Archives/edgar/data/320193/000032019323000106/aapl-20230930.htm
#   This is the official SEC filings for 10-K for Apple
#   all information bracketed with red lines are available here, others are not!
#
#
# Good-to-know:
#   if analyzing specific company, company may changed name
#   'sub_df' contains 
#     - 'former' variable that is the former entities name
#     - 'changed' is the date when company changed name
#     so to get full history check if the first filing has these values
#     if they have the company has changed name/(legal) status

library(data.table)
library(tidyverse)

#####
# set the folder path
folder_path <- "/Users/areguly6/Library/CloudStorage/OneDrive-CorvinusUniversityofBudapest/Research/XBRL/"
data_in <- 'data/SEC_raw'

# Type of gathering data:
#   - 'SVB' -- Silicon Valley Bank example
#   - '10K' -- Collect all 10-Ks (balance sheets + Profit & Losses)
#   - '10K-Banks' -- Collect 10-Ks for Banks only (Fama-French 30 SIC categorization)
#   - 'MA' -- searches for S-4 or S-4/A document that needs to be filed if M&A happens

type_gather <- '10K'#'MA'#'SVB'

# Define the CIK number for Silicon Valley Bank ()
cik_svb <- 719739

# Define SIC codes for Banks (broad definition)
sic_banks <- c(6000,6199)

# Collect text data or not? (memory intensive...)
text_data <- F

if ( type_gather == 'MA' ){
  text_data <- T
}

# Get the folders in data directory
folders <- list.dirs(paste0(folder_path,data_in))
# remove the original directory
folders <- folders[2:length(folders)]

folders <- folders[55:60]

# As of 2024/02 there should be 60 folders containing data (2009q1 is empty...)

# To avoid overloading the memory, only selected variables will be read from the data
# Check the variable descriptions from the pdf
num_cols <- c('adsh','tag','version','coreg','ddate','qtrs','uom','value')#'footnote'
tag_cols <- c('tag','version','custom','datatype')
sub_cols <- c('adsh','cik','name','sic','former','changed','afs','fye','form','period','fy','accepted') # ,'ncik'
pre_cols <- c('adsh','tag','version','report','line','stmt','inpth','plabel')

#fdirs <- folders[15]

for ( fdirs in folders){
  
  iter_id <- substr(fdirs,(nchar(fdirs)-5),nchar(fdirs) )
  print(paste0('Iteration for: ', iter_id ) )
  
  ####
  # 1) Import individual files
  # Numerical values
  num_df <- fread( paste0(fdirs,'/num.txt'), select = num_cols )
  # Tag files
  tag_df <- fread( paste0(fdirs,'/tag.txt'), select = tag_cols )
  # Submitted doc key file
  sub_df <- fread( paste0(fdirs,'/sub.txt'), select = sub_cols )
  # Text files for submission (skip if not needed as takes lot of time)
  if ( text_data ){
    pre_df <- fread( paste0(fdirs,'/pre.txt'), select = pre_cols )
  }
  
  ####
  # 2) Filter for different types
  
  ###
  # 2a) Silicon Valley Bank
  if ( type_gather == 'SVB' ){
  
    sub_df <- sub_df[ cik == cik_svb, ]
      
    # 2b) All 10-Ks
    #   i) 10-Ks
    #   ii) US-GAAP type of accounting report
    #   iii) company filed the report itself (empty or NA values)
  } else if( type_gather %in% c('10K','10K-Banks')){
    
    # i)
    sub_df <- sub_df[form %in% c('10-K','10-K/A'), ]
    # ii)
    num_df <- num_df[substr(version,1,7) == 'us-gaap', ]
    # iii)
    num_df <- num_df[is.na(coreg) | coreg == '', ]
    
    # 2c) Banks with 10-Ks
    #   use 2b) filter and filter SIC codes as well
    if ( type_gather == '10K-Banks' ){
      
      # Filter out according to SIC values from Fama-French 48 industry categorization
      sub_df <- sub_df[ sic >= sic_banks[1] & sic <= sic_banks[2],  ]
      
    }
  } else if( type_gather == 'MA' ){
    
    # Filing for M&A
    sub_df <- sub_df[form %in% c('S-4','S-4/A'), ]
    
  }
  
  #######
  # 3) Do the merging of data
  
  if ( nrow( sub_df ) > 0 ){
    #  a) Match with numeric values
    df_i <- merge(sub_df, num_df, by = 'adsh', all.x = T )
    
    # b) Match with tags
    df_i <- merge( df_i, tag_df, by = c('tag','version'), all.x = T )
    
    # c) Match with text (if needed)
    if ( text_data ){
      df_i <- merge( df_i, pre_df, by = c('tag','adsh','version'), all.x = T )
    }
    
    ####
    # 4) Append
    if ( nrow( df_i ) > 0 ){
      if( !exists( "df_out" ) ){
        df_out = df_i
      } else{
        df_out = rbind( df_out, df_i )
      }
    }
    
  } else {
    print( paste0( 'Potential problem with iteration: ', iter_id , ' There are no observations after filtering and merging! ' ) )
  } 
  
}

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
               # If you need to aggregate multiple tags to get the final value
               c('') ~ 'ivst'
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




