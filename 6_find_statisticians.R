# 6_find_statisticians.R
# using method from https://pubmed.ncbi.nlm.nih.gov/32816788/
# one coauthor affiliated with a biostatistics, statistics, data science, data analytics, epidemiology, maths, computer science or economics department
# April 2026
library(readxl)
library(tidyr)
library(dplyr)
library(openalexR)
library(stringr)
source('0_my_openalex_get_do_not_share.R')
source('99_functions.R')

# from 4_exclude.R
load('data/4_combined_papers.RData') #  files: 'papers'

# loop through departments
departments = NULL
for (k in 1:nrow(papers)) {
  f1 = find_stats_department(papers$doi[k])
  departments = bind_rows(departments, f1)
}

# change from T/F
departments = mutate(
  departments,
  statistician = case_when(
    statistician == TRUE ~ 'Yes',
    statistician == FALSE ~ 'No'
  )
)

# save
save(departments, file = 'data/6_departments.RData')

### Part 2
## validation against Sainani paper https://pubmed.ncbi.nlm.nih.gov/32816788/; shared by David Borg
sainani = read_excel(
  'data/6_Eligible papers_biostasts coauthor data_final_DB.xlsx'
) %>%
  mutate(Title = str_remove(Title, ':$')) # remove trailing colon

# use rentrez (pubmed) to find papers by their title (misses some)
library(rentrez)
pubmeds = NULL
for (k in 1:nrow(sainani)) {
  query = paste(sainani$Title[k], '[ti] AND 2019[pdat]', sep = '') # restrict to 2019
  eres = entrez_search(db = 'pubmed', term = query, retmode = 'xml')
  if (eres$count > 0) {
    frame = data.frame(row = k, pmid = eres$ids[1], matches = eres$count)
  }
  if (eres$count == 0) {
    frame = data.frame(row = k, pmid = NA, matches = 0)
  }
  pubmeds = bind_rows(pubmeds, frame)
}


# next find DOIs from openalex by searching using PMID
to_check = filter(pubmeds, matches == 1) %>% # only those with a single match
  mutate(doi = NA, department = NA)
for (k in 1:nrow(to_check)) {
  results = oa_fetch(
    entity = 'works',
    pmid = to_check$pmid[k],
    api_key = my_open_alex_key,
    mailto = 'a.barnett@qut.edu.au',
    options = list(
      select = c('publication_year', 'doi', 'title')
    )
  )
  if (is.null(results)) {
    next
  }
  to_check$doi[k] = str_remove(results$doi, 'https://doi.org/')
  to_check$department[k] = find_stats_department(to_check$doi[k])$statistician
}

# now merge with Sainani data and compare
sainani = mutate(sainani, row = 1:n())
to_compare = full_join(to_check, sainani, by = 'row')
with(to_compare, table(department, Stats_coauthor)) # agreement
# gwet's agreement
ratings = select(to_compare, department, Stats_coauthor) %>%
  mutate(department = as.numeric(department))
irrCAC::gwet.ac1.raw(ratings = ratings)
# look at disagreements
filter(to_compare, department == FALSE, Stats_coauthor == 1)

# "Combined total hip and knee arthroplasty during the same hospital admission: Is it safe?:" Says 'epidemiology' but I don't see it
# "Controlled ecological evaluation of an implemented exercise-training programme to prevent lower limb injuries in sport" ditto
