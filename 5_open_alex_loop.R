# 5_open_alex_loop.R
# loop through open alex papers; here because it needs to be called twice
# called from 5_open_alex.R
# November 2025

for (k in 1:length(res)){
  this_res = res[[k]] # get item in list
  #
  this_doi = str_remove(this_res$doi, "https://doi.org/")
  #
  authors_list = this_res$authorships # list 
  authors = unlist(purrr::map(authors_list, "raw_affiliation_strings")) # just extract this list element; although is sometimes empty
  index = str_detect(tolower(authors),'australian? institute of sport|\\bAIS\\b')
  if(is.null(authors)){index = NA}
  frame = data.frame(doi = this_res$doi,
                     date = as.Date(this_res$publication_date),
                     type = this_res$primary_location$source$type,
                     journal = this_res$primary_location$raw_source_name, 
                     publisher = this_res$primary_location$source$host_organization_name,
                     title = this_res$title, # paper's title
                     n_total = length(authors_list), # total number of authors
                     n_ais = sum(index), # number of AIS authors
                     first_author = any(index == 1), # keep, but these are not as good as the data from the RA (Alex)
                     last_author = any(index == nrow(authors)),
                     cited = this_res$cited_by_count
  )
  ais_authors = bind_rows(ais_authors, frame)
  
  # All authors
  n_authors = length(authors_list)
  if(n_authors > 0){
    author_ids = unlist(purrr::map(purrr::map(authors_list, "author"), 'id'))
    for (j in 1:n_authors){
      if(is.na(author_ids[j])){next}
      this_author = oa_fetch(identifier = author_ids[j], 
                             mailto = "a.barnett@qut.edu.au", # 
                             entity = 'authors') %>%
        select(any_of(author_vars)) %>% # get what's available
        mutate(doi = this_doi)
      author_frame = bind_rows(author_frame, this_author)
    }
  }
  if(n_authors == 0){cat('Error, no authors for ', this_doi, '\n')}
  
  # topics
  topics_list = this_res$topics
  topics = data.frame(doi = this_res$doi, topics = unlist(purrr::map(topics_list, 'display_name')))
  if(nrow(topics) == 0){next} # skip if nothing
  topics_non_list = bind_rows(topics_non_list, topics) # fill up blank page
}

# tidy
ais_authors = mutate(ais_authors,
                     doi = str_remove(doi, pattern='https://doi.org/'))
