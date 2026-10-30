# 5_read_pdf_comments_by_RA.R
# read and process PDF comments added by Alex (the research assistant) and the random sample by Ran
# see protocol for which questions are manual
# see 5_read_pdf_files_to_xml_automate.R for automated questions
# August 2025
library(dplyr)
library(XML)
library(stringr)
library(tidyr) # for pivot
library(textclean) # for words to numbers
source('99_patterns.R') # text patterns

# DOIs to exclude from 4_exclude.R (also removed excluded PDFs from folder)
load('data/4_combined_papers.RData')
remove(papers) # not needed

## files to use; run once for all three
# Adrian
directory = 'data/pdf_comments/adrian' # 20 files
outfile = 'data/5_audit_check2.RData'
# Ran
directory = 'data/pdf_comments/ran' # 20 files
outfile = 'data/5_audit_check.RData'
# Alex
directory = 'data/pdf_comments' #
outfile = 'data/5_audit.RData'
#outfile = 'data/5_audit_pre_fix.RData' # before fixing data errors

# files in this directory, had to save comments to xfdf file
files = dir(directory, pattern = '\\.xfdf$') # search for comments
# exclude safety net
dois_to_exclude = str_replace(dois_to_exclude, '/', '_') #  replace / with '_'
dois_to_exclude = paste(dois_to_exclude, collapse = '|')
fexcluded = files[str_detect(files, pattern = dois_to_exclude)] # use string detect because these are PDFs
files = files[!str_detect(files, pattern = dois_to_exclude)] # use string detect because these are PDFs
cat('There were ', length(fexcluded), ' files excluded.\n', sep = '') # only AIS authors
cat('There were ', length(files), ' files included.\n', sep = '')

# checking files - do not run
#source('99_compare_pdf.R')

## part 1: read the comments for all papers ##

# loop through comments
data = NULL
for (f in files) {
  # file name
  infile = paste(directory, '/', f, sep = '')
  # get the DOI
  doi = str_replace_all(f, '_', '/')
  doi = str_remove_all(doi, '\\.xfdf')
  #
  raw = xmlParse(infile) # read in
  top = xmlRoot(raw) # get top-level node
  tnames = names(top[[1]])
  for (k in 1:length(tnames)) {
    # loop through multiple comments
    art = top[[1]][[k]]
    text = as.character(xmlSApply(art[[1]], xmlValue)) # extract comment
    if (length(text) == 0) {
      next # skip to next; empty comment
    }
    if (text %in% c('Q', 'q')) {
      next # skip to next; empty comment
    }
    if (str_detect(text, pattern = ':') == FALSE) {
      # first search for semi-colon instead of colon
      semi = str_detect(text, semi_pattern)
      if (semi == TRUE) {
        text = str_replace(text, semi_pattern, ': ') # add back colon
      }
      # next search for nothing
      no_colons = str_detect(text, no_colon_pattern)
      if (no_colons == TRUE) {
        text = str_replace(text, no_colon_pattern, ': ') # add back colon
      }
      if (semi == FALSE & no_colons == FALSE) {
        cat('DOI =', doi, ', Q=', k, sep = '')
        stop('No colon.\n')
      } # stop if no colon
    }
    text_split = str_split_fixed(text, ':', n = 2) # just first colon by using _fixed version; avoids multiple splits if more than 1 colon
    # extract into data frame and add to data
    frame = data.frame(
      doi = doi,
      q = tolower(text_split[1]),
      comment = tolower(str_squish(text_split[2])) # convert to lower case for string search
    )
    data = bind_rows(data, frame)
  }
}
# remove other comments
data = filter(data, q != 'other')
# data cleaning
data = mutate(
  data,
  comment = str_replace_all(comment, '\n', ' '), # remove any carriage returns
  comment = str_replace_all(comment, ',,', ','), # accidental double commas
  q = str_replace_all(q, pattern = missing_q, replacement = 'q')
) # add back q to start of question

# check for small/large number of questions answered:
tab = table(data$doi)
tab[tab > 16] # more than expected (should be empty)
tab[tab < 16] # fewer than expected (should be empty)
#filter(data, doi=='10.1519/jsc.0000000000003035') %>% group_by(q) %>% tally() # double responses
## check missing questions ##
tab = with(data, table(doi, q))
long = reshape::melt(tab) # ignore warnings
filter(long, value == 0) %>%
  group_by(q) %>%
  tally() # should be empty
filter(long, value == 0) # list of what is missing (should be empty)

## part 2: process the comments for all papers ##

# Paper type (q1a)
# one of Review, observational, protocol, experimental, or other
type = filter(data, q == 'q1a') %>%
  mutate(
    type = case_when(
      str_detect(comment, 'protocol') ~ 'Protocol', # not in our protocol!
      str_detect(comment, 'review\\b') ~ 'Review',
      str_detect(comment, 'survey') ~ 'Observational study',
      str_detect(comment, 'meta.?analys(i|e)s') ~ 'Review',
      str_detect(comment, 'validation') ~ 'Observational study',
      str_detect(comment, 'case.control') ~ 'Observational study',
      str_detect(comment, '^experimental|\\btrial\\b') ~ 'Experimental study',
      str_detect(comment, 'qualitative . observational') ~ 'Other', # for one from Ran
      str_detect(comment, 'observational') ~ 'Observational study',
      str_detect(comment, '^pilot|^consensus|^qualitative') ~ 'Other',
      str_detect(comment, '^other') ~ 'Other', # moved lower so that `survey` is classed as observational
      TRUE ~ as.character(comment)
    )
  ) %>%
  select(-q) %>% # no longer needed, but keep original text
  unique() # safety net for duplicates

# Count the number of authors with an AIS affiliation (q1b); get author position too
# partly automated using openalex, see 5_open_alex.R, but openAlex is not as good as actual Alex!
ais_authors = filter(data, q == 'q1b') %>%
  mutate(
    number = as.numeric(str_extract(comment, pattern = a_pattern)),
    f_pos = as.numeric(str_extract(comment, pattern = f_pattern)), # number of first author
    l_pos = as.numeric(str_extract(comment, pattern = l_pattern)), # number of last author
    total = as.numeric(str_extract(comment, pattern = t_pattern)), # total number of authors
    first = f_pos == 1, # is first author
    last = l_pos == total
  ) %>% # is last author
  select(-q, -comment, -l_pos, -f_pos) %>% # no longer needed
  unique() # safety net for duplicates
filter(ais_authors, is.na(total)) # check

# Was any author a statistician (q1c)
# CHANGED TO AUTOMATED, see 5_automate_statistician.R

# Q2a: Did the paper have a well-formed research question or study aim?
# see 99_patterns.R for strings used in matches
question = filter(data, q == 'q2a') %>%
  mutate(
    question = case_when(
      str_detect(
        comment,
        pattern = '\\bna\\b|not applicable'
      ) ~ "Not applicable",
      str_detect(
        comment,
        pattern = no_aims_but_purpose
      ) ~ "Purpose/Objective/Statement/Goal", # take if first match
      str_detect(comment, pattern = no_aims) ~ "No",
      str_detect(comment, pattern = yes_aims) ~ "Yes",
      TRUE ~ as.character(comment)
    )
  ) %>%
  select(-q) %>% # no longer needed
  unique() # safety net for duplicates
# check for any uncategorised text
filter(
  question,
  nchar(question) > 10 &
    !str_detect(question, '/') &
    !str_detect(question, 'Not applicable')
) %>%
  select(question)


# Q2b: How many research questions or aims were there? Added aims
question_number = filter(data, q == 'q2b') %>%
  mutate(
    comment = str_replace(comment, 'qeuestions', 'questions'), # fix type
    aims_n = str_extract(comment, pattern = '[0-9](?= (research )?aims?)'),
    aims_n = mgsub(aims_n, replace_number(seq_len(100)), seq_len(100)), # change words to numerals
    aims_n = ifelse(str_detect(comment, 'no aims?'), 0, aims_n), # when there are no aims
    #
    question_n = str_extract(
      comment,
      pattern = '[0-9](?= (research )?questions?)'
    ),
    question_n = mgsub(question_n, replace_number(seq_len(100)), seq_len(100)),
    question_n = ifelse(
      str_detect(comment, 'no aims? or research'),
      0,
      question_n
    ), # when there are no aims
    # added after data collection (purpose or goal):
    purpose_n = str_extract(
      comment,
      pattern = '[0-9](?= ((study|research) )?(goals?|purposes?|objectives?)(of study)?)'
    ),
    question = case_when(
      str_detect(
        comment,
        pattern = '\\bna\\b|not applicable|^0$'
      ) ~ "Not applicable",
      !is.na(question_n) ~ question_n,
      TRUE ~ as.character(comment)
    )
  ) %>%
  select(-q, -comment) %>% # no longer needed
  unique() %>% # safety net for duplicates
  mutate(
    aims_n = as.numeric(aims_n),
    question_n = as.numeric(question_n),
    purpose_n = as.numeric(purpose_n)
  )
# if only number in answer then can assume it's an aim
question_number = mutate(
  question_number,
  aims_n = case_when(
    is.na(aims_n) &
      is.na(question_n) &
      is.na(purpose_n) &
      nchar(question) == 1 ~ as.numeric(question),
    TRUE ~ aims_n
  )
)
# check (should be empty):
filter(
  question_number,
  is.na(question_n) &
    is.na(aims_n) &
    is.na(purpose_n) &
    question != "Not applicable"
)

# Q2c: Can the question(s) be expressed using an established framework? For example, PICO for clinical studies or SPIDER for qualitative studies.
my.into = paste('aims', 1:4, sep = '') # new columns
# multiple aims per paper is possible, so split into aims (allowing multiple per study)
framework_long = filter(data, q == 'q2c') %>%
  separate(col = 'comment', sep = ':', into = my.into) %>%
  select(-q) %>%
  pivot_longer(-doi) %>%
  filter(!is.na(value)) %>%
  mutate(
    value = str_replace(value, ' one', ' 1'),
    value = str_replace(value, ' two', ' 2'),
    value = str_remove(value, 'expressed by '),
    value = str_remove(
      value,
      pattern = '(research questions?|objectives?|questions?|aims?|purpose of study|purpose|prupose) ?[1-9]'
    ), # don't need this info any more
    value = str_squish(value)
  ) %>%
  filter(value != '', !str_detect(value, '^aim$|^purpose of study$')) %>%
  rename('comment' = 'value')
framework = mutate(
  framework_long,
  question = case_when(
    str_detect(comment, pattern = pico_partial) ~ "PICO, partial", # comes first
    str_detect(comment, pattern = pico_yes) ~ "PICO",
    str_detect(comment, pattern = spider_yes) ~ "SPIDER",
    str_detect(comment, pattern = spider_partial) ~ "SPIDER, partial",
    str_detect(comment, pattern = no_framework) ~ "No",
    str_detect(comment, pattern = '\\bna\\b|not applicable') ~ "Not applicable",
    str_detect(
      comment,
      pattern = 'no research (questions?|aims?)'
    ) ~ "Not applicable",
    TRUE ~ as.character(comment)
  )
) %>%
  select(-name) %>% # no longer needed
  unique() # safety net for duplicates
table(framework$question) # check

# Q3: Was there previous research on the same question(s)? (Did they cite a review or do their own review?)
# many responses gave two reasons
prior = filter(data, q == 'q3') %>%
  mutate(
    prior = case_when(
      str_detect(
        comment,
        pattern = '\\bna\\b|not applicable|infographic'
      ) ~ "Not applicable",
      str_detect(comment, pattern = not_mentioned) ~ "Not mentioned at all", # comes first
      str_detect(
        comment,
        pattern = no_justification
      ) ~ "Mentioned but no justification was made", #
      str_detect(
        comment,
        pattern = mentioned_but_justified
      ) ~ 'Mentioned but this research justified',
      TRUE ~ as.character(comment)
    ),
    # separate variables
    same_pop = str_detect(comment, pattern = mentioned_but_justified) &
      str_detect(comment, pattern = same_population), # "Mentioned but this research justified as the previous research wasn’t in the same population"
    more_evidence = str_detect(comment, pattern = mentioned_but_justified) &
      str_detect(comment, pattern = more_evidence_needed), # "Mentioned but this research justified as more evidence was needed to change practices"
    had_flaws = str_detect(comment, pattern = mentioned_but_justified) &
      str_detect(comment, pattern = had_flaws) # "Mentioned but this research justified as the previous research was flawed/error/wrong etc"
  ) %>%
  select(-q, -comment) %>% # no longer needed
  unique() # safety net for duplicates
table(prior$prior) # should be four categories
table(prior$same_pop) #
table(prior$had_flaws)

# AUTOMATED, see 5_read_pdf_files_to_xml_automate.R: Q4a: Was there a study protocol and/or analysis plan?
# AUTOMATED, see 5_read_pdf_files_to_xml_automate.R: Q4b: Was the study pre-registered, e.g., ANZCTR or clintrials.gov?

#	Q5a: Was there a sample size calculation for the research question?
sample_size = filter(data, q == 'q5a') %>%
  mutate(
    comment = str_replace_all(
      comment,
      'caluclation|calcualtion',
      'calculation'
    ), # fix spelling error
    any_sample_size = case_when(
      str_detect(
        comment,
        pattern = '\\bna\\b|not? applicable'
      ) ~ "Not applicable",
      str_detect(comment, pattern = no_sample_size) ~ "No",
      str_detect(comment, pattern = yes_sample_size) ~ "Yes",
      TRUE ~ as.character(comment)
    )
  ) %>%
  select(-q, -comment) %>% # no longer needed
  unique() # safety net for duplicates
table(sample_size$any_sample_size) # should be only three categories

# Q5b: If yes to Q5a, was the effect size justified in the sample size calculation? We will not judge the validity of the justification; the interest is whether any justification was given.
sample_size_justified = filter(data, q == 'q5b') %>%
  mutate(
    sample_size_justified = case_when(
      str_detect(
        comment,
        pattern = '\\bna\\b|not? applicable'
      ) ~ "Not applicable",
      str_detect(comment, pattern = size_justified) ~ "Yes",
      str_detect(comment, pattern = size_not_justified) ~ "No",
      TRUE ~ as.character(comment)
    )
  ) %>%
  select(-q, -comment) %>% # no longer needed
  unique() # safety net for duplicates
table(sample_size_justified$sample_size_justified) # should be only three categories

# Q5c: What was the sample size? target
sample_size_target = filter(data, q == 'q5c') %>%
  mutate(
    comment = ifelse(
      comment == '10 participants per treatment group',
      'n=20',
      comment
    ), # a few edits
    comment = ifelse(comment == '14, 7 per group', 'n=14', comment), #
    comment = ifelse(
      comment == 'between 12 and 18 participants',
      'n=16',
      comment
    ), # went half way for simplicity
    comment = ifelse(
      comment == '10 participants per treatment group',
      'n=30',
      comment
    ), # had to check number of groups (three)
    number = str_extract(comment, number_pattern),
    number = as.numeric(number),
    comment = case_when(
      str_detect(
        comment,
        pattern = 'not? reported|could not determine'
      ) ~ "Not reported",
      str_detect(
        comment,
        pattern = '\\bna\\b|not? applicable'
      ) ~ "Not applicable"
    )
  ) %>%
  select(-q) %>% # no longer needed
  unique() # safety net for duplicates
table(sample_size_target$number) # should just be numbers

# Q5d: What was the sample size? actual
sample_size_actual = filter(data, q == 'q5d') %>%
  mutate(
    number = str_extract(comment, number_pattern),
    number = as.numeric(number),
    comment = case_when(
      str_detect(
        comment,
        pattern = '\\bna\\b|not? applicable'
      ) ~ "Not applicable",
      str_detect(
        comment,
        pattern = 'not? (stated|reported)|could not determine'
      ) ~ "Not reported",
      TRUE ~ as.character(comment)
    )
  ) %>%
  select(-q) %>% # no longer needed
  unique() # safety net for duplicates
table(sample_size_actual$number) # should just be numbers

# gender (q6), number of male and female participants
fpattern = c(
  '[0-9][0-9]?[0-9]?[0-9]?[0-9]?[0-9]?(?= females?)',
  '(?<=females? )[0-9][0-9]?[0-9]?[0-9]?[0-9]?[0-9]?'
)
fpattern = paste(fpattern, collapse = '|')
mpattern = c(
  '[0-9][0-9]?[0-9]?[0-9]?[0-9]?[0-9]?(?= males?)',
  '\\b(?<=males? )[0-9][0-9]?[0-9]?[0-9]?[0-9]?[0-9]?'
)
mpattern = paste(mpattern, collapse = '|')
gender = filter(data, q == 'q6') %>%
  mutate(
    gender_not_applicable = str_detect(
      comment,
      pattern = '\\bna\\b|not? applicable'
    ),
    gender_not_reported = str_detect(
      comment,
      pattern = 'not? (seen )?reported|not found to be reported|\\bunclear\\b|could not determine'
    ),
    female = str_extract(
      comment,
      pattern = fpattern,
    ),
    male = str_extract(
      comment,
      pattern = mpattern,
    ),
    other = str_extract(
      comment,
      pattern = '[0-9][0-9]?[0-9]?[0-9]?[0-9]?[0-9]?(?= other)'
    ),
    female = as.numeric(female),
    female = ifelse(is.na(female), 0, female), # NAs to zero
    male = as.numeric(male),
    male = ifelse(is.na(male), 0, male), # NAs to zero
    other = as.numeric(other),
    other = ifelse(is.na(other), 0, other), # NAs to zero
    female_only = male == 0 & other == 0 & female > 0,
    male_only = male > 0 & female == 0 & other == 0
  ) %>%
  select(-q, -comment) %>% # no longer needed
  unique() # safety net for duplicates
table(gender$female) # should just be numbers

# check that male/female split adds to sample size (check with Alex)
check = full_join(sample_size_actual, gender, by = 'doi') %>%
  filter(gender_not_applicable == FALSE) %>% # remove papers where gender does not matter
  filter(number != female + male) %>% # total number does not add to male plus female
  select(doi, number, female, male) %>%
  filter(!(male == 0 & female == 0)) # if both zero then assume that male and female were not given
check # lots that do not add up; sometimes due to missing gender data (e.g., from survey)

# automated: Q7. Ethics, see 5_read_pdf_files_to_xml_automate.R
# automated: Q8. Was there a data availability statement? , see 5_read_pdf_files_to_xml_automate.R
# automated: Q9: Were there statements on funding and a conflict of interest? , see 5_read_pdf_files_to_xml_automate.R

# Q10: Were missing data discussed and/or correctly reported?
missing = filter(data, q == 'q10') %>%
  mutate(
    comment = str_replace_all(comment, 'reproted', 'reported'), # fix typo
    discussed = case_when(
      str_detect(
        comment,
        pattern = '\\bna\\b|not? applicable'
      ) ~ "Not applicable",
      str_detect(comment, pattern = missing_no) ~ "No",
      str_detect(comment, pattern = '\\bremoved\\b') &
        str_detect(comment, pattern = 'no justification') ~ "No", # when they are removed
      str_detect(comment, pattern = missing_yes) ~ "Yes",
      str_detect(comment, pattern = missing_none) ~ "No data missing",
      TRUE ~ as.character(comment)
    )
  ) %>%
  select(-q, -comment) %>% # no longer needed
  unique()
table(missing$discussed) # should just be four categories

# Q11: Were outliers removed without justification?
# need an example for when outliers were removed without justification
outliers = filter(data, q == 'q11') %>%
  mutate(
    comment = str_replace_all(comment, 'reproted', 'reported'), # fix typo
    outliers = case_when(
      str_detect(
        comment,
        pattern = '\\bna\\b|not? applicable'
      ) ~ "Not applicable",
      str_detect(comment, pattern = outliers_no) ~ "No outliers removed",
      str_detect(comment, pattern = outliers_no_just) ~ "Yes, no justification",
      str_detect(comment, pattern = outliers_just) ~ "Yes, with justification",
      TRUE ~ as.character(comment)
    )
  ) %>%
  select(-q, -comment) %>% # no longer needed
  unique()
table(outliers$outliers)
# error with 10.1096/fj.202002205rr

# automated: Q12a: Was a relevant EQUATOR reporting guideline mentioned?, see 5_read_pdf_files_to_xml_automate.R
# automated: Q13. Was the publication open access (green, gold)?, see 5_read_pdf_files_to_xml_automate.R

# Q14a: Was the research question answered? (Did the authors reflect on the question)
question_answered = filter(data, q == 'q14a') %>%
  mutate(
    comment = str_replace_all(comment, ' th ', ' the '), # fix typo
    comment = str_replace_all(comment, 'anwered', 'answered'), # fix typo
    answered = case_when(
      str_detect(comment, pattern = questions_yes) ~ "Yes",
      str_detect(comment, pattern = questions_no) ~ "No",
      str_detect(
        comment,
        pattern = '\\bna\\b|^not applicable|^no specific aim or research question'
      ) ~ "Not applicable",
      TRUE ~ as.character(comment)
    )
  ) %>%
  select(-q, -comment) %>% # no longer needed
  unique()
table(question_answered$answered)

# Q14b: Was there some reflection about the practical significance of the main result/outcome.
practical_significance = filter(data, q == 'q14b') %>%
  mutate(
    answered = case_when(
      str_detect(comment, pattern = practical_yes) ~ "Yes",
      str_detect(comment, pattern = practical_no) ~ "No",
      str_detect(
        comment,
        pattern = '\\bna\\b|^not applicable'
      ) ~ "Not applicable",
      TRUE ~ as.character(comment)
    )
  ) %>%
  select(-q, -comment) %>% # no longer needed
  unique()
table(practical_significance$answered)

# Q14c: Was there an over-interpretation of the study results, for example, making causal claims from a small observational study ?
# this question is not processed, instead it's output to AIS experts (see 6_read_interpretation.R)
# however, what's in the text is Alex's section of the interpretation
interpretation = filter(data, q == 'q14c') %>%
  rename('response' = 'comment') %>%
  select(-q) %>% # no longer needed
  unique()

## Check for missing questions
# put all data together
type_long = rename(type, 'response' = 'type') %>% mutate(question = 'type')
question_long = rename(question, 'response' = 'question') %>%
  mutate(question = 'research_question')
question_number_long1 = select(question_number, 'doi', 'aims_n') %>%
  rename('response' = 'aims_n') %>%
  mutate(question = 'aims_n') %>%
  mutate(response = as.character(response))
question_number_long2 = select(question_number, 'doi', 'question_n') %>%
  rename('response' = 'question_n') %>%
  mutate(question = 'question_n') %>%
  mutate(response = as.character(response))
framework_long = select(framework, 'doi', 'question') %>%
  rename('response' = 'question') %>%
  mutate(question = 'framework')
prior_long = select(prior, 'doi', 'prior') %>%
  rename('response' = 'prior') %>%
  mutate(question = 'prior')
sample_size_long = select(sample_size, 'doi', 'any_sample_size') %>%
  rename('response' = 'any_sample_size') %>%
  mutate(question = 'any_sample_size')
sample_size_justified_long = select(
  sample_size_justified,
  'doi',
  'sample_size_justified'
) %>%
  rename('response' = 'sample_size_justified') %>%
  mutate(question = 'sample_size_justified')
sample_size_actual_long = select(sample_size_actual, 'doi', 'number') %>%
  rename('response' = 'number') %>%
  mutate(question = 'actual') %>%
  mutate(response = as.character(response))
sample_size_target_long = select(sample_size_target, 'doi', 'number') %>%
  rename('response' = 'number') %>%
  mutate(question = 'target') %>%
  mutate(response = as.character(response))
gender_long = select(gender, 'doi', 'female') %>%
  rename('response' = 'female') %>%
  mutate(question = 'female') %>%
  mutate(response = as.character(response))
missing_long = select(missing, 'doi', 'discussed') %>%
  rename('response' = 'discussed') %>%
  mutate(question = 'discussed')
outliers_long = select(outliers, 'doi', 'outliers') %>%
  rename('response' = 'outliers') %>%
  mutate(question = 'outliers')
question_answered_long = select(question_answered, 'doi', 'answered') %>%
  rename('response' = 'answered') %>%
  mutate(question = 'answered')
practical_significance_long = select(
  practical_significance,
  'doi',
  'answered'
) %>%
  rename('response' = 'answered') %>%
  mutate(question = 'practical')
# now combine
long = bind_rows(
  type_long,
  question_long,
  question_number_long1,
  question_number_long2,
  framework_long,
  prior_long,
  sample_size_long,
  sample_size_justified_long,
  sample_size_actual_long,
  sample_size_target_long,
  gender_long,
  missing_long,
  outliers_long,
  question_answered_long,
  practical_significance_long
) %>%
  mutate(any = response != '' & !is.na(response))
# cross-tabulation to find any response
tab = group_by(long, doi, question, any) %>%
  tally() %>%
  select(-any) %>%
  pivot_wider(names_from = 'question', values_from = 'n') %>%
  mutate_all(~ replace_na(0))
# table should all be `1`
summary(tab) # to find missing by variable (all stats be zero)

## save ##
save(
  long, # save long version too, useful for random checks
  type,
  ais_authors,
  question,
  question_number,
  framework,
  sample_size,
  sample_size_justified,
  sample_size_actual,
  sample_size_target,
  gender,
  missing,
  outliers,
  question_answered,
  prior,
  practical_significance,
  interpretation,
  file = outfile
)

# list of data extraction:
# Q1a: Study design, one of four: review, experimental study, observational study, other (e.g., qualitative)
# Q1b: The number of authors with an AIS affiliation. We will record if they were the first or last author.
# Q2a: Did the paper have a well-formed research question or study aim?
# Q2b: How many research questions or aims were there?
# Q2c: Can the question(s) be expressed using an established framework? For example, PICO for clinical studies or SPIDER for qualitative studies.
# Q3: Was there previous research on the same question(s)? (Did they cite a review or do their own review?) Potential responses:
#	Q5a: Was there a sample size calculation for the research question?
# Q5b: If yes to Q5a, was the effect size justified in the sample size calculation? We will not judge the validity of the justification; the interest is whether any justification was given.
# Q5c: What was the target sample size?
# Q5d: What was the actual sample size?
# Q6: number of male and female participants
# Q10: Were missing data discussed and/or correctly reported?
# Q11: Were outliers removed without justification?
# Q14a: Was the research question answered? (Did the authors reflect on the question)
# Q14b: Was there some reflection about the practical significance of the main result/outcome.
