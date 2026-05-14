# 3_export_excel.R
# export papers to Excel for RA for checking
# also exports sub-sample for checking
# November 2025
library(dplyr)
library(openxlsx)
library(readxl)
library(stringr)

# papers from 2_compare_combine_databases.R
load('data/2_combined_papers.RData')

# get papers from first and second batch using the Excel file from March 2025
first_batch = read.xlsx('data/3_papers.xlsx', sheet = 1) 
second_batch = read.xlsx('data/3_papers_extra.xlsx', sheet = 1) 
first_second_batch = bind_rows(first_batch, second_batch)

# now get new papers
merged = anti_join(papers, first_second_batch, by='doi') # in papers but not in first batch
papers = merged # rename for update

# randomly order
TeachingDemos::char2seed('birmingham')
papers = mutate(papers, random = runif(n=n())) %>%
  arrange(desc(random)) %>%
  select(year, doi, journal, title)

# export to Excel
#filename = 'data/3_papers.xlsx' # first batch
#filename = 'data/3_papers_extra.xlsx' # additional papers found in August
filename = 'data/3_papers_extra_two.xlsx' # additional papers found in October
wb = createWorkbook(creator='Adrian Barnett')
addWorksheet(wb, sheetName = "papers")
freezePane(wb, sheet = 1, firstRow = TRUE) ## freeze first column
writeDataTable(wb, sheet = 1, x = papers,
               colNames = TRUE, rowNames = FALSE)
saveWorkbook(wb, filename, overwrite = TRUE)

## sub-sample for Ran to check
sub_sample = sample_n(papers, 20) %>%
  select(year, doi, journal, title)
#
filename = 'data/3_papers_ran_check.xlsx' # additional papers found in October
wb = createWorkbook(creator='Adrian Barnett')
addWorksheet(wb, sheetName = "papers")
freezePane(wb, sheet = 1, firstRow = TRUE) ## freeze first column
writeDataTable(wb, sheet = 1, x = sub_sample,
               colNames = TRUE, rowNames = FALSE)
saveWorkbook(wb, filename, overwrite = TRUE)

  