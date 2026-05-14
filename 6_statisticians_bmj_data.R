# 6_statisticians_bmj_data.R
# using the BMJ roles information to find authors who are statisticians
# this file gathers the data ready for modelling
# May 2026
library(dplyr)
library(tidyr)
library(europepmc) # for full text of PMCID
library(xml2)
library(rvest)
library(openalexR)
library(rcrossref) # for PMID to PMCID
library(rentrez) # for pubmed search
source('0_my_openalex_get_do_not_share.R')

## Part 1: get BMJ papers from pubmed ##
years = 2015:2026
all_search = NULL
for (y in years) {
  query = paste0('"BMJ"[jour] AND ', y, '[pdat] AND ffrft[Filter]') # BMJ in quotes; must be fully open for PMCID
  psearch = entrez_search(db = 'pubmed', term = query, retmax = 1000)
  cat('Year = ', y, ', count = ', psearch$count, '\n', sep = '') #  check matches
  all_search = c(all_search, psearch$ids) # concatenate PMIDs
}
all_search = unique(all_search) # safety net for duplicates
cat('There are ', length(all_search), ' papers.\n', sep = '')

## Part 2: get meta-data and author IDs from OpenAlex ##
metadata = excluded = NULL

# second run for PMCIDs that are missing
all_search = filter(excluded, reason == 'No PMCID') %>% pull(pmid)

start = 1 # for restarts (should be 1); occasional lexical errors solved by trying again
for (k in start:length(all_search)) {
  # get PMCID
  this_pmcid = tryCatch(
    {
      id_converter(all_search[k], type = 'pmid')$records$pmcid
    },
    error = function(e) {
      NULL
    }
  )
  # if no PMCID then exclude and skip (but try again in second pass)
  if (is.null(this_pmcid) == TRUE) {
    eframe = data.frame(pmid = all_search[k], reason = 'No PMCID')
    excluded = bind_rows(excluded, eframe)
    next
  }

  # fetch meta-data from OpenAlex
  this_meta = oa_fetch(
    entity = 'works',
    pmid = all_search[k],
    mailto = 'a.barnett@qut.edu.au',
    api_key = my_open_alex_key,
    options = list(
      select = c('ids', 'authorships')
    )
  )

  # no record in openalex
  if (is.null(this_meta) == TRUE) {
    eframe = data.frame(pmid = all_search[k], reason = 'No OpenAlex record')
    excluded = bind_rows(excluded, eframe)
    next
  }

  # if no authors then exclude and skip (e.g., retraction notice)
  if (nrow(this_meta$authorships[[1]]) == 0) {
    eframe = data.frame(pmid = all_search[k], reason = 'No authors')
    excluded = bind_rows(excluded, eframe)
    next
  }

  # add PMCID and concatenate
  this_meta = mutate(this_meta, pmcid = this_pmcid)
  metadata = bind_rows(metadata, this_meta)

  # report progress
  if (k %% 10 == 0) {
    cat('Up to', k, '\r')
  }
}
metadata = unique(metadata) # safety net from restarts
excluded = unique(excluded)
# remove from excluded - need to have pmid in there
#excluded = filter(excluded, )

## Part 3: get roles from full text using europepmc ##
author_data = mismatch_check = NULL
start = 2135
for (j in start:nrow(metadata)) {
  # full text as an XML using PMCID
  ft = tryCatch(
    {
      epmc_ftxt(ext_id = metadata$pmcid[j])
    },
    error = function(e) {
      NULL
    }
  )
  # if not available, e.g., PMC12135075
  if (is.null(ft) == TRUE) {
    eframe = data.frame(pmcid = metadata$pmcid[j], reason = 'XML not available')
    excluded = bind_rows(excluded, eframe)
    next
  }

  # extract roles
  this_roles = html_nodes(
    ft,
    xpath = "//front/article-meta/contrib-group/contrib/role"
  ) %>%
    html_text()
  # some have no roles, e.g., PMC7618446; exclude these ones
  if (length(this_roles) == 0) {
    eframe = data.frame(pmcid = metadata$pmcid[j], reason = 'No roles')
    excluded = bind_rows(excluded, eframe)
    next
  }

  ## extract names
  # surname
  this_surname = html_nodes(
    ft,
    xpath = "//front/article-meta/contrib-group/contrib/name/surname"
  ) %>%
    html_text()
  # first name
  this_first = html_nodes(
    ft,
    xpath = "//front/article-meta/contrib-group/contrib/name/given-names"
  ) %>%
    html_text()
  this_names = paste(tolower(this_first), tolower(this_surname)) # combine names and switch to lower case to match

  # first check that all names have roles; exclude if not because we cannot match names to roles
  if (length(this_roles) != length(this_names)) {
    eframe = data.frame(
      pmcid = metadata$pmcid[j],
      reason = 'Mismatched names and roles'
    )
    excluded = bind_rows(excluded, eframe)
    next
  }

  # extract key author data into a frame
  frame = metadata$authorships[j][[1]] %>%
    select(
      -affiliations,
      -affiliation_raw,
      -is_corresponding,
      -author_position,
      -orcid
    )

  # if no mismatch in length assume names and roles are in order
  if (nrow(metadata$authorships[j][[1]]) == length(this_roles)) {
    frame = mutate(frame, role = this_roles, name = this_names, name_diff = NA)
    for (s in 1:nrow(frame)) {
      frame$name_diff[s] = compare_names(frame$name[s], frame$display_name[s])
    }
    maybe_mismatch = filter(frame, name_diff > 0.33) %>%
      select(display_name, name, name_diff)
    if (nrow(maybe_mismatch) > 0) {
      # store mismatches
      mismatch_check = bind_rows(mismatch_check, maybe_mismatch)
    }
  }

  # if mismatch in length then merge on names
  if (nrow(metadata$authorships[j][[1]]) != length(this_roles)) {
    #
    rframe = data.frame(role = this_roles, name = this_names) # frame of roles and names
    frame = mutate(frame, display_name = tolower(display_name)) %>%
      left_join(rframe, join_by('display_name' == 'name')) # merge for those in openalex data
    if (nrow(frame) == 0) {
      eframe = data.frame(
        pmcid = metadata$pmcid[j],
        reason = 'No matching authors'
      )
      excluded = bind_rows(excluded, eframe)
      next
    }
  }

  # concatenate
  frame = mutate(frame, PMCID = metadata$pmcid[j])
  author_data = bind_rows(author_data, frame)

  # report progress
  if (j %% 10 == 0) {
    cat('Up to', j, '\r')
  }
}
author_data = unique(author_data) # due to restarts
# useful to look at the XML
#write_xml(ft, file = 'pmc2.xml')

# consider exclusions
group_by(excluded, reason) %>% tally()

## refine the data
# examine mismatches:
# View(filter(mismatch_check, name_diff>=0.50))
# based on above use 0.5 as threshold (this does exclude some valid matches, but also kicks out some mismatches)
author_data = filter(author_data, name_diff < 0.5)

# flag statistical jobs
stats_words = c('biostat', '\\bstatist', 'data scien', 'analy', 'methodologist')
stats_all = paste(stats_words, collapse = '|')
author_data = mutate(
  author_data,
  role = str_squish(role),
  role = tolower(role), # safety net for odd role in capitals
  statistician = str_detect(role, pattern = stats_all)
)
table(author_data$statistician)

# if there are multiple authors then take any statistician
# lost around 5000 duplicates
any_stat = group_by(author_data, id) %>%
  arrange(id, desc(statistician)) %>%
  slice(1) %>%
  ungroup()

# check
# jobs = filter(author_data, statistician) %>% pull(role) %>% unique(); jobs[order(jobs)]

## part 4 - get track records from OpenAlex ##
data = NULL
start = 1 # for restarts
for (k in start:nrow(any_stat)) {
  from_oa = oa_fetch(
    identifier = any_stat$id[k],
    entity = 'authors',
    api_key = my_open_alex_key,
    options = list(select = c('id', 'display_name', 'topics')),
    mailto = 'a.barnett@qut.edu.au'
  )
  Sys.sleep(1) # to avoid time outs
  frame = data.frame(from_oa$topics[[1]]) %>%
    mutate(
      name = any_stat$display_name[k],
      statistician = any_stat$statistician[k]
    )
  data = bind_rows(data, frame)
  # report progress
  if (k %% 50 == 0) {
    cat('Up to', k, '\r')
  }
}
data = unique(data) # safety net for restarts

## data from wide to long
# type = 'topic' -> too many columns
# type = 'subfield' -> 236 columns
# type = 'field' -> only 28 columns, too few?
wide = filter(data, type == 'subfield') %>%
  select(-i, -id) %>%
  pivot_wider(
    id_cols = c(name, statistician),
    values_fn = sum,
    names_from = 'display_name',
    values_from = 'count'
  ) %>%
  mutate(across(everything(), ~ replace_na(., 0)))

# check numbers
with(wide, table(statistician))
with(data, table(statistician))
table(any_stat$statistician)
prop.table(table(any_stat$statistician))

## save
save(data, wide, excluded, file = 'data/6_bmj_roles.RData')
