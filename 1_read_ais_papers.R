# 1_read_ais_papers.R
# read AIS papers from the search done by the AIS
# had to enter some DOIs into the Excel sheet
# there are some ineligible papers, e.g., from "Western Australian Institute of Sport"; however, data does not include institution
# September 2025
library(readxl)
library(dplyr)
library(janitor)
library(tidyr)
library(stringr)
library(openalexR) # to get affiliation data
# get affiliation text (needed to find AIS authors)
source('1_affiliations.R')

# loop through sheets
years = excel_sheets('data/Published AIS Research articles list 2000-2024 (Paolo Menaspa).xlsx')
years = as.character(2020:2024) # only need these years
vars_to_keep = c('Author', "Article Title", "Journal Title", "Publication Date", "DOI", 'Subjects', 'Keywords','Abstract','Doctype')
papers = NULL
for (y in years){
  one_year = read_excel('data/Published AIS Research articles list 2000-2024 (Paolo Menaspa).xlsx',
                      sheet = y) %>%
    select(any_of(vars_to_keep)) %>% # don't need a lot of variables; causes errors
    mutate(year = as.numeric(y),
           DOI = str_squish(DOI),
           DOI = tolower(DOI)) # for merging with RW database
  papers = bind_rows(papers, one_year)
}
papers = papers %>% 
  clean_names()  
# check
non_missing = filter(papers, !is.na(doi))
table(duplicated(non_missing$doi))
index = which(duplicated(non_missing$doi))
non_missing = filter(non_missing, doi == non_missing[index[1],]$doi)

## Removals 
# a) remove duplicates with two dates
nrow(papers)
papers = group_by(papers, article_title) %>%
  arrange(papers, year) %>%
  slice(1) %>%
  ungroup()
nrow(papers)

# b) types of output to exclude
exclude = c("CD-ROM",'Letter','Videocassette','Published Erratum','Interview','Comment')
papers = filter(papers, 
                !is.na(doctype), # exclude if missing
                !doctype %in% exclude)

# c) remove one double
index = papers$doi == '10.1111/sms.14272' & papers$year == 2023
papers = papers[!index,]

# d) one paper is not in English
index = papers$doi == '10.33155/j.ramd.2020.11.004'
papers = papers[!index,]

# e) remove "Western Australian Institute of Sport", "South Australian Sports Institute"
# need to get affiliation data from openalex
dois = filter(papers, !is.na(doi), doi != '999') %>% pull(doi)
oa_results = oa_fetch(
  entity = "works",
  doi = dois,
  verbose = TRUE,
  mailto = 'a.barnett@qut.edu.au',
  count_only = FALSE
)
oa_slim = select(oa_results, doi, author)
# loop to find affiliations
# note, this does not always work, e.g., https://journals.plos.org/plosone/article/authors?id=10.1371/journal.pone.0274806, the openalex data misses AIS affiliation
# also, https://doi.org/10.1002/jor.24622
# hence decided not to use, but kept code
aff_check = NULL
for (i in 1:nrow(oa_slim)){
  this_author = oa_slim$author[i][[1]]
  big_string = tolower(paste(this_author$au_affiliation_raw, collapse=' '))
  is_ais = any(str_detect(tolower(big_string), pattern = paste(tolower(affl), collapse='|')))
  is_other = any(str_detect(tolower(big_string), pattern = paste(tolower(affl_ex), collapse='|')))
  # if other, then check if AIS is still there after removing excluded affiliations
  if(is_other == TRUE){
    without = str_remove_all(tolower(big_string), pattern = paste(tolower(affl_ex), collapse='|'))
    is_ais = any(str_detect(without, pattern = paste(tolower(affl), collapse='|')))
  }
  frame = data.frame(doi = oa_slim$doi[i], is_ais = is_ais, is_other = is_other)
  aff_check = bind_rows(aff_check, frame)
}

# list of authors
authors = NULL
for (k in 1:nrow(papers)){
   frame = data.frame(name = str_split(papers$author[k], pattern=';')[[1]])
   authors = bind_rows(authors, frame)
}
authors = mutate(authors,
                 name = str_squish(name),
                 name = str_to_title(name))

# list of keywords
subjects = NULL
for (k in 1:nrow(papers)){
  frame = data.frame(subjects = str_split(papers$subjects[k], pattern=';')[[1]])
  subjects = bind_rows(subjects, frame)
}
subjects = mutate(subjects,
                  subjects = str_squish(subjects))

## save
save(authors, papers, subjects, exclude, file = 'data/1_articles.RData')
