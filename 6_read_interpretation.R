# 6_read_interpretation.R
# read in the interpretations of David and Paolo for question 14c
# data exported to Excel from 5_export_interpretation.R
# November 2025
library(readxl)
library(dplyr)
library(janitor)

# Paolo's data
paolo = read_excel('data/5_interpretation_Paolo_complete.xlsx',
                   sheet = 'Interpretations',
                   na = 'NA') %>% 
  clean_names() %>%
  mutate(expert = 'Paolo') %>%
  rename('interpretation' = 'answer_true_overinterpreted_false_not_overinterpreted_na') %>%
  select(doi, interpretation, comment, expert) %>%
  mutate(interpretation = as.logical(interpretation))
# David's data 
david = read_excel('data/5_interpretation_David_complete.xlsx',
                           sheet = 'Interpretations',
                           na = 'NA') %>% 
  clean_names() %>%
  mutate(expert = 'David') %>%
  rename('interpretation' = 'answer') %>%
  select(doi, interpretation, comment, expert)

# look at agreement
agree = full_join(paolo, david, by='doi') %>%
  filter(!is.na(interpretation.x), !is.na(interpretation.y)) # both non-missing
tabyl(agree, interpretation.x, interpretation.y)

# combine data and remove duplicates
TeachingDemos::char2seed('cardiff')
interpretation = bind_rows(paolo, david) %>%
  mutate(random = runif(n())) %>%
  group_by(doi) %>%
  arrange(doi, random) %>%
  slice(1) %>% # select one expert at random
  ungroup() %>%
  select(-random)
table(table(interpretation$doi)) # should all be 1 (check)

# save 
save(interpretation, file = 'data/6_interpretation.RData')
