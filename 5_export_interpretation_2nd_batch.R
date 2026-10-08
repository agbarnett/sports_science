# 5_export_interpretation_2nd_batch.R
# Export the interpretations for question 14c into an Excel file
# second batch
# Sep 2026
library(openxlsx)
library(dplyr)
library(readxl)

# data from 5_open_alex.R for title
load('data/5_open_alex.RData')
title = select(open_alex_data, doi, title)
# data from 5_read_pdf_comments_by_RA.R; has `interpretation`
load('data/5_audit.RData')
# add study design and sample size to interpretation
interpretation = left_join(interpretation, type, by = 'doi') %>%
  left_join(sample_size_actual, by = 'doi') %>%
  left_join(title, by = 'doi') %>%
  select(doi, title, type, number, response) %>% # do not need question
  mutate(answer = '', comment = '') %>%
  rename('sample size' = 'number')

# remove those already done
done1 = read_excel(path = 'data/5_interpretation_David_complete.xlsx')
done2 = read_excel(path = 'data/5_interpretation_Paolo_complete.xlsx')
done = bind_rows(done1, done2) %>%
  select(doi) %>%
  unique()
interpretation = anti_join(interpretation, done, by = 'doi')

# split into two random groups with an overlap of 10
N = nrow(interpretation)
half = N / 2
TeachingDemos::char2seed('rotherham')
interpretation = sample_n(interpretation, replace = FALSE, size = N)
david = interpretation[1:(half + 5), ] # create an overlap of 10
paolo = interpretation[(half - 5):N, ]

## export to excel - make sure to rename excel file after data collection
cwidths = c(14, 20, 20, 11, 145, 11, 30) # column widths
header_style <- createStyle(
  fontColour = "white",
  fgFill = "darkorange2",
  halign = "left",
  valign = "center",
  wrapText = TRUE,
  textDecoration = "Bold",
  border = "TopBottomLeftRight"
) #
body_style <- createStyle(
  fontColour = "black",
  fgFill = "white",
  halign = "left",
  valign = "top",
  wrapText = TRUE,
  border = "TopBottomLeftRight"
) #
# David
wb <- createWorkbook(
  title = 'Interpretation',
  creator = 'Adrian Barnett',
  subject = 'created by 5_export_interpretation_2nd_batch.R'
)
# sheet 1
addWorksheet(wb, sheetName = 'Interpretations', gridLines = TRUE)
writeData(
  wb,
  sheet = 'Interpretations',
  x = david,
  startRow = 1,
  headerStyle = header_style
)
addStyle(
  wb,
  sheet = 'Interpretations',
  style = body_style,
  rows = 2:205,
  cols = 1:7,
  gridExpand = TRUE
)
setColWidths(wb, sheet = 'Interpretations', cols = 1:7, widths = cwidths)
# save
saveWorkbook(wb, "data/5_interpretation_David_second.xlsx", overwrite = TRUE)
# Paolo
wb <- createWorkbook(
  title = 'Interpretation',
  creator = 'Adrian Barnett',
  subject = 'created by 5_export_interpretation_2nd_batch.R'
)
# sheet 1
addWorksheet(wb, sheetName = 'Interpretations', gridLines = TRUE)
writeData(
  wb,
  sheet = 'Interpretations',
  x = paolo,
  startRow = 1,
  headerStyle = header_style
)
addStyle(
  wb,
  sheet = 'Interpretations',
  style = body_style,
  rows = 2:205,
  cols = 1:7,
  gridExpand = TRUE
)
setColWidths(wb, sheet = 'Interpretations', cols = 1:7, widths = cwidths)
# save
saveWorkbook(wb, "data/5_interpretation_Paolo_second.xlsx", overwrite = TRUE)
