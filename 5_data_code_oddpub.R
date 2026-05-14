# 5_data_code_oddpub.R
# look for mentions of data and code using the oddpub library (note, this worked best in study with Anita and Peter for the automated screening working group)
# see https://github.com/quest-bih/oddpub
# Aug 2025
library(dplyr)
library(stringr)
library(oddpub) # for data and code
source('99_functions.R') # for str_replace_doi

# location of PDFs:
directory = 'data/pdfs' # PDFs for main trial

# make sure PDFs don't have excluded
# Converts PDFs contained in one folder to txt-files: (recursive off; do not do sub-folders)
oddpub::pdf_convert(pdf_folder = directory, recursive = FALSE, overwrite_existing_files = FALSE, output_folder = 'pdf_as_txt') # takes a while
# Loads all text files from given folder:
pdf_text_sentences <- pdf_load('pdf_as_txt')
# Actual Open Data detection:
open_data_results <- open_data_search(pdf_text_sentences) # takes a while

# add DOI
open_data_results = mutate(open_data_results, 
                           doi = str_remove(article, '\\.txt$'))
# had to use loop for modified str_replace
for (k in 1:nrow(open_data_results)){
  open_data_results$doi[k] = str_replace_doi(open_data_results$doi[k])
}

# DOIs to exclude from 4_exclude.R (also removed excluded PDFs from folder) - safety net as results should be excluded already
load('data/4_combined_papers.RData')
#remove(authors, papers, topics, search_date) # not needed
open_data_results = filter(open_data_results, !doi %in% dois_to_exclude)

# check
table(table(open_data_results$doi))

# save
save(open_data_results, file = 'data/5_oddpub.RData')
