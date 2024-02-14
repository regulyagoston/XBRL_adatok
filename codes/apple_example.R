######
# This is an example code to collect data based onb different purposes, using
#   XBRL data
#
# We only get Apple's values with this script that is available at:
# Go and check out: https://www.sec.gov/ixviewer/ix.html?doc=/Archives/edgar/data/320193/000032019323000106/aapl-20230930.htm
#   This is the official SEC filings for 10-K for Apple
#   all information bracketed with red lines are available here, others are not!
#

library(data.table)
library(tidyverse)

#####
# set the folder path
folder_path <- "C:/Users/areguly/OneDrive - Corvinus University of Budapest/Research/XBRL/"
data_in <- 'data/SEC_raw'
fdirs <- paste0(folder_path,data_in,'/2023q4')

# Type of gathering da
  ####
  # 1) Import individual files
  # Numerical values
  num_df <- fread( paste0(fdirs,'/num.txt') )
  # Tag files
  tag_df <- fread( paste0(fdirs,'/tag.txt') )
  # Submitted doc key file
  sub_df <- fread( paste0(fdirs,'/sub.txt') )
  # Text files for submission (skip if not needed as takes lot of time)
  pre_df <- fread( paste0(fdirs,'/pre.txt') )
  
 
  # Filter for Apple's 10-K
  apple_cik <- 320193
  sub_df <- sub_df[cik==apple_cik,]
  sub_df <- sub_df[form=='10-K',]
  
  # Select US-GAAP and sent by the company itself
  num_df <- num_df[substr(version,1,7) == 'us-gaap', ]
  num_df <- num_df[is.na(coreg) | coreg == '', ]
  
  #  a) Match with numeric values
  df_i <- merge(sub_df, num_df, by = 'adsh', all.x = T )
    
  # b) Match with tags
  df_i <- merge( df_i, tag_df, by = c('tag','version'), all.x = T )
    
  # c) Match with text
  df_i <- merge( df_i, pre_df, by = c('tag','adsh','version'), all.x = T )

