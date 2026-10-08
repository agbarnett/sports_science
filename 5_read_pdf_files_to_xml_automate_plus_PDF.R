# 5_read_pdf_files_to_xml_automate_plus_PDF.R
# read PDF papers and automate parts of the audit using XML code
# see protocol for which questions are automated
# version that uses PDF as a back-up
# see 5_read_pdf_comments_by_RA.R for manually-entered questions; 5_data_code_oddpub.R for data/code
# Septemeber 2026
library(dplyr)
library(metacheck) # for grobid reader to turn PDFs in XMLs; was "papercheck"
library(pdftools) # to read PDF as a back-up to XML
library(stringr)
library(textclean) # for cleaning text so that regex works better
library(roadoi) # for open access
source('99_functions.R') # for extracting text function
# regex patterns for finding code, data, etc:
source('99_patterns.R')

# DOIs to exclude from 4_exclude.R (also removed excluded PDFs from folder)
load('data/4_combined_papers.RData')
remove(papers) # not needed

# directory with PDFs
directory = '../pilot/2_pilot_pdfs' # second pilot
directory = '../pilot/3_pilot_pdfs' # third pilot with signed-off protocol
directory = 'data/pdfs' # main trial
files = dir(directory, pattern = '\\.pdf$')
# exclude safety net (PDFs should be already moved to )
dois_to_exclude = str_replace(dois_to_exclude, '/', '_') #  replace / with '_'
dois_to_exclude = paste(dois_to_exclude, collapse = '|')
files = files[!str_detect(files, pattern = dois_to_exclude)] # use string detect because these are PDFs

# loop through in PDF
all_data = NULL
for (f in files) {
  # get the DOI
  doi = str_replace_doi(f) # see 99_functions.R
  doi = str_remove_all(doi, '\\.pdf')
  if (doi == '999') {
    next
  } # cannot get results for this one as there's no DOI
  # make sure there is a prefix in the DOI
  if (str_count(doi, '/') == 0) {
    cat("Problem with DOI: ", doi, "\n", sep = '')
  }

  ## make PDF into XML
  # using GROBID to make into an XML; see https://grobid.readthedocs.io/en/latest/Introduction/ and https://github.com/scienceverse/papercheck
  infile = paste(directory, '/', str_replace(f, '/', '_'), sep = '')
  # do not run conversion if XML already exists
  xml_version = str_remove(f, '\\.pdf$') %>% str_replace('/', '_')
  exists = length(dir(path = 'xml', pattern = xml_version)) > 0
  if (exists == TRUE) {
    xml_version = paste('xml/', xml_version, '.xml', sep = '')
  }
  if (exists == FALSE) {
    xml_version = pdf2grobid(infile, save_path = 'xml') # put in XML folder
  }
  paper <- read(xml_version) # parse XML, puts full text into single sentences
  # also have PDF
  pdf_version = paste('data/pdfs/', f, sep = '')
  paper_pdf <- pdf_text(pdf_version) #

  # check length, flag very long or short
  plength = nrow(paper$full_text)
  if (plength < 100 | plength > 450) {
    cat('Length = ', nrow(paper$full_text), ' for DOI = ', doi, '\n', sep = '')
  }
  # two very short ones (20,21) are infographics. Long one (650) is systematic review.

  # use checks from papercheck, p-values check is not currently working
  #pvals = module_run(paper, "all_p_values") # get all p-values - does not work, see https://github.com/scienceverse/papercheck/issues/49
  #rw = module_run(paper, "retractionwatch") # run retraction watch checks; turned off (April 2026), use crossref instead

  ## use multiple functions from textclean to help with regex:
  # a) XML
  full_text = mutate(
    paper$full_text,
    text = replace_hash(text),
    text = replace_white(text),
    text = replace_curly_quote(text),
    # text = replace_time(text, pattern = textclean_time_pattern), # see 99_patterns; commented out because of warnings
    text = str_replace_all(text, '\\*', ' '),
    lower_text = tolower(text)
  ) %>% # add lower case to simplify matches
    filter(section != 'foot') # remove text from footnote, often download stuff
  # b) PDF (character)
  full_text_pdf = paste(paper_pdf, collapse = ' ')
  full_text_pdf = replace_hash(full_text_pdf)
  full_text_pdf = replace_white(full_text_pdf)
  full_text_pdf = replace_curly_quote(full_text_pdf)
  full_text_pdf = str_replace_all(full_text_pdf, '\\*', ' ')
  full_text_pdf = tolower(full_text_pdf) # add lower case to simplify matches

  ## odd fixes from PDF conversion? e.g. par- ticipant, approv- al; not needed with XML? check again
  #  hyphen_remove = '(?<=[a-z])- (?=[a-z])'
  # text = str_remove_all(text, pattern = hyphen_remove)
  # filter(full_text, str_detect(text, '- ')) # looking for PDF conversion problems

  ## pre-registration indicators, such as "as predicted" and OSF, also if it's a registered report
  pre_registration = find_and_extract_xml_and_pdf(
    full_text,
    full_text_pdf,
    in_pattern = registration_pattern
  )

  # Q9: Was there a conflict of interest statement?
  conflict = find_and_extract_xml_and_pdf(
    full_text,
    full_text_pdf,
    in_pattern = conflict_pattern
  ) # see 99_functions.R and 99_patterns.R

  # Q9: Was there any funding statement
  funding = find_and_extract_xml_and_pdf(
    full_text,
    full_text_pdf,
    in_pattern = funding_pattern
  ) # see 99_functions.R and 99_patterns.R

  # Q4a: Was there a study protocol and/or analysis plan?
  protocol_find = find_and_extract_xml_and_pdf(
    full_text,
    full_text_pdf,
    in_pattern = protocol_pattern
  )
  analysis_plan_find = find_and_extract_xml_and_pdf(
    full_text,
    full_text_pdf,
    in_pattern = plan_pattern
  )
  # remove one false positive match
  if (str_detect(doi, '10.1186.s40798-024-00791-9')) {
    analysis_plan_find$was_found = FALSE
  }

  #	Q7: Was ethical clearance mentioned or was there a statement on why ethical clearance was not needed?
  ethics_find = find_and_extract_xml_and_pdf(
    full_text,
    full_text_pdf,
    in_pattern = ethical_pattern
  ) # see 99_functions.R

  # Q12: Was a relevant EQUATOR reporting guideline mentioned?
  # use text that is not all lower case for acronyms
  equator = find_and_extract_xml_and_pdf(
    full_text,
    full_text_pdf,
    in_pattern = equator_pattern,
    upper = TRUE
  ) # use upper case text

  # Q13. Was the publication open access (green, gold)?
  # trycatch for occasional error, e.g., "10.14589/ido.20.4.5"
  oa = tryCatch(
    oadoi_fetch(doi, email = "a.barnett@qut.edu.au"),
    error = function(e) {
      'error'
    }
  ) # change words to numbers
  if (class(oa)[1] == 'character') {
    oa_result = oa_status = NA
  }
  if (class(oa)[1] != 'character') {
    oa_result = oa$is_oa
    oa_status = oa$oa_status
  }

  # Q1b. AIS author affiliation and author position using open-alex

  # extra question - Did anyone mention "National High Performance Sport Research Agenda (NHPSRA)
  # should be from 2022 onwards only
  NHPSRA = find_and_extract_xml_and_pdf(
    full_text,
    full_text_pdf,
    in_pattern = NHPSRA_pattern
  )

  # extra question - what software was used
  programmes = NA
  software = find_and_extract_xml_and_pdf(
    full_text,
    full_text_pdf,
    in_pattern = software_pattern
  )
  if (software$was_found == TRUE) {
    programmes = str_extract_all(
      tolower(software$extract_text),
      pattern = software_pattern
    )[[1]]
    programmes = unique(str_squish(programmes))
    programmes = programmes[order(programmes)] # alphabetical order
    programmes = paste(programmes, collapse = '; ')
  }

  # count the words; useful for checking size of paper
  all_text = pull(full_text, text) %>% paste(collapse = ' ')
  n_words = str_count(all_text, '\\w+') #

  # concatenate and save
  indicators = data.frame(
    doi = doi,
    protocol = protocol_find$was_found,
    protocol_text = protocol_find$extract_text,
    analysis_plan = analysis_plan_find$was_found,
    analysis_plan_text = analysis_plan_find$extract_text,
    ethics = ethics_find$was_found,
    ethics_text = ethics_find$extract_text,
    equator = equator$was_found,
    equator_text = equator$extract_text,
    is_oa = oa_result,
    oa_status = oa_status,
    conflict = conflict$was_found,
    conflict_text = conflict$extract_text,
    funding = funding$was_found,
    funding_text = funding$extract_text,
    registration = pre_registration$was_found,
    registration_text = pre_registration$extract_text,
    software = software$was_found,
    programmes = programmes,
    software_text = software$extract_text,
    NHPSRA = NHPSRA$was_found,
    NHPSRA_text = NHPSRA$extract_text,
    #retraction_watch = nrow(rw$table), # turned off, use crossref instead (April 2026)
    n_words = n_words
  )
  if (nrow(indicators) > 1) {
    cat('Too many rows for DOI:', doi, '\n')
  }

  # concatenate
  all_data = bind_rows(all_data, indicators)
}

# checks
if (nrow(all_data) != length(files)) {
  cat('Not enough data.\n')
}
if (length(files) != nrow(all_data)) {
  cat('Error, missing files in data.\n')
}

# update one paper manually that was not available to roaodi
all_data = mutate(
  all_data,
  is_oa = ifelse(doi == '10.14589/ido.20.4.5', TRUE, is_oa),
  oa_status = ifelse(doi == '10.14589/ido.20.4.5', 'gold', oa_status)
)

# add one paper manually that had no DOI (https://pubmed.ncbi.nlm.nih.gov/32139349/)
# res = oa_fetch(entity = 'works', pmid = 32139349, output = 'tibble');
one_paper = data.frame(
  doi = '999',
  equator = FALSE,
  analysis_plan = FALSE,
  ethics = TRUE,
  ethics_text = 'Ethical approval for the study was granted by the Australian Institute of Sport Ethics Committee (Approval number 20160407) and the Griffith University Human Ethics Committee (HREC 2016/213)',
  equator = FALSE,
  conflict = TRUE,
  conflict_text = 'Conflicts of Interest: Nil',
  funding = TRUE,
  funding_text = 'This work was supported by the Australian Institute of Sport High Performance Research Fund, the Queensland Academy of Sport Centre of Excellence for Applied Sport Science Research (Grant Number CoE056 and Griffith University (Internal Grant)',
  is_oa = FALSE,
  registration = FALSE,
  software = TRUE,
  programmes = 'nsolver; spss',
  software_text = 'Differences in group characteristics were evaluated in SPSS version 25 (IBM Computing, New York, USA).',
  NHPSRA = FALSE,
  NHPSRA_text = '',
  oa_status = 'closed'
)
all_data = bind_rows(all_data, one_paper)


## save
auto_data = all_data
search_date = as.Date(Sys.Date()) # save date of search
save(auto_data, search_date, file = 'data/5_automated.RData')
