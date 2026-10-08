# 6_read_interpretation.R
# read in the interpretations of David and Paolo for question 14c
# data exported to Excel from 5_export_interpretation.R
# November 2025
library(readxl)
library(dplyr)
library(janitor)
library(irrCAC) # for Gwet
library(openxlsx)

## up to here
# these data are not working in 8_articles_report.Rmd

## Paolo's data
# batch 1
paolo1 = read_excel(
  'data/5_interpretation_Paolo_complete.xlsx',
  sheet = 'Interpretations',
  na = 'NA'
) %>%
  clean_names() %>%
  mutate(expert = 'Paolo') %>%
  rename(
    'interpretation' = 'answer_true_overinterpreted_false_not_overinterpreted_na'
  ) %>%
  select(doi, interpretation, comment, expert) %>%
  mutate(interpretation = as.logical(interpretation))
# batch 2
paolo2 = read_excel(
  'data/5_interpretation_Paolo_second_complete.xlsx',
  sheet = 'Interpretations',
  na = 'NA'
) %>%
  clean_names() %>%
  mutate(expert = 'Paolo') %>%
  rename(
    'interpretation' = 'answer_true_overinterpreted_false_not_overinterpreted_na'
  ) %>%
  select(doi, interpretation, comment, expert) %>%
  mutate(interpretation = as.logical(interpretation))
paolo = bind_rows(paolo1, paolo2)
## David's data
# batch 1
david1 = read_excel(
  'data/5_interpretation_David_complete.xlsx',
  sheet = 'Interpretations',
  na = 'NA'
) %>%
  clean_names() %>%
  mutate(expert = 'David') %>%
  rename('interpretation' = 'answer') %>%
  select(doi, interpretation, comment, expert)
# batch 2
david2 = read_excel(
  'data/5_interpretation_David_second_complete.xlsx',
  sheet = 'Interpretations',
  na = 'NA'
) %>%
  clean_names() %>%
  mutate(expert = 'David') %>%
  rename(
    'interpretation' = 'answer_true_overinterpreted_false_not_overinterpreted_na'
  ) %>%
  select(doi, interpretation, comment, expert) %>%
  mutate(interpretation = as.logical(interpretation))
david = bind_rows(david1, david2)

# look at agreement
agree = full_join(paolo, david, by = 'doi') %>%
  filter(!is.na(interpretation.x), !is.na(interpretation.y)) # both non-missing
tabyl(agree, interpretation.x, interpretation.y)
#
gwet = gwet.ac1.raw(agree[, c('interpretation.x', 'interpretation.y')])

## resolve disagreements
disagree = filter(agree, interpretation.x != interpretation.y)
## export to excel - make sure to rename excel file after data collection
header_style <- createStyle(
  fontColour = "white",
  fgFill = "darkorange2",
  halign = "left",
  valign = "center",
  wrapText = TRUE,
  textDecoration = "Bold",
  border = "TopBottomLeftRight"
) #
#
wb <- createWorkbook(
  title = 'Resolve disagreements',
  creator = 'Adrian Barnett',
  subject = 'created by 6_read_interpretation.R'
)
# sheet
addWorksheet(wb, sheetName = 'Disagreements', gridLines = TRUE)
freezePane(wb, sheet = 'Disagreements', firstRow = TRUE)
writeData(
  wb,
  sheet = 'Disagreements',
  x = disagree,
  startRow = 1,
  headerStyle = header_style
)
setColWidths(
  wb,
  sheet = 'Disagreements',
  cols = 1:7,
  widths = c(28, 8, 28, 8, 8, 28, 8)
)
# save
saveWorkbook(
  wb,
  "checks/6_resolve_interpretation_disagreements.xlsx",
  overwrite = TRUE
)

# fix disagreements, all resolved to TRUE
interpretation = bind_rows(paolo, david)
dois_to_change = pull(disagree, doi)
index = interpretation$doi %in% dois_to_change
interpretation$interpretation[index] = TRUE

# remove duplicates
TeachingDemos::char2seed('cardiff')
interpretation = bind_rows(paolo, david) %>%
  mutate(random = runif(n())) %>%
  group_by(doi) %>%
  arrange(doi, random) %>%
  slice(1) %>% # select one expert at random - this is okay, because agreement was 100% after meeting about disagreements
  ungroup() %>%
  select(-random)
table(table(interpretation$doi)) # should all be 1 (check)

# save
save(interpretation, file = 'data/6_interpretation.RData')
