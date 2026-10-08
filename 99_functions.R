# 99_functions.R
# functions for AIS study
# May 2025

## compare two names, used by 6_statisticians_bmj.R
compare_names = function(name1, name2){
  # compare names as lower case letters
  count1 = str_count(tolower(name1), pattern = letters)
  count2 = str_count(tolower(name2), pattern = letters)
  diff = sum(abs(count1 - count2)) # absolute difference (could weight by less common letters?)
  length = max(c(sum(count1), sum(count2))) # largest number of letters
  prop = diff / length # proportion out
  return(prop)
}

## function to find pattern and extract relevant text from text processed by XMLs
# called by 5_read_pdf_files_to_xml_automate.R
find_and_extract_xml = function(
  intext, # data frame
  in_pattern, # pattern to find
  upper = FALSE # using upper case text
) {
  was_found = FALSE
  extract_text = '' # start blank

  # run search
  if (upper == FALSE) {
    found = filter(
      intext,
      str_detect(lower_text, pattern = in_pattern) | # look in text ...
        str_detect(tolower(header), pattern = in_pattern) # ... and header (e.g., "conflict of interest" as a sub-header)
    )
  }
  if (upper == TRUE) {
    found = filter(
      intext,
      str_detect(text, pattern = in_pattern) |
        str_detect(header, pattern = in_pattern)
    )
  }
  was_found = nrow(found) > 0
  if (was_found == TRUE) {
    # get all sentences; could add full stop to sentences that do not have one.
    extract_text = pull(found, text) %>% paste(collapse = ' ')
  }

  to.return = data.frame(was_found = was_found, extract_text = extract_text)
  return(to.return)
} # End of function

## function to find pattern and extract relevant text from text processed by XMLs and PDF
# called by 5_read_pdf_files_to_xml_automate_plus_PDF.R
find_and_extract_xml_and_pdf = function(
    intext, # data frame for XML
    inpdf, # character
    in_pattern, # pattern to find
    upper = FALSE   # using upper case text
) {
  was_found = FALSE
  extract_text = '' # start blank
  
  # run search
  if (upper == FALSE) {
    found_xml = filter(
      intext,
      str_detect(lower_text, pattern = in_pattern) | # look in text ...
        str_detect(tolower(header), pattern = in_pattern) # ... and header (e.g., "conflict of interest" as a sub-header)
    )
    found_pdf = str_detect(tolower(inpdf), pattern = in_pattern) 
  }
  if (upper == TRUE) {
    found_xml = filter(
      intext,
      str_detect(text, pattern = in_pattern) |
        str_detect(header, pattern = in_pattern)
    )
    found_pdf = str_detect(inpdf, pattern = in_pattern) 
  }
  was_found = nrow(found_xml) > 0 | found_pdf == TRUE
  if (was_found == TRUE) {
    # get all sentences; could add full stop to sentences that do not have one.
    extract_text = pull(found_xml, text) %>% paste(collapse = ' ')
    # if XML is blank then use PDF
    if(extract_text == ''){
      extract_text = str_extract_all(inpdf, pattern = in_pattern) %>% paste(collapse = ' ')
    }
  }
  
  to.return = data.frame(was_found = was_found, extract_text = extract_text)
  return(to.return)
} # End of function


## function to find pattern and extract relevant text from text processed by PDFs
find_and_extract = function(intext, in_pattern) {
  found = str_locate_all(intext, pattern = in_pattern)[[1]] # can be far apart if multiple sections in paper
  was_found = FALSE
  extract_text = '' # start blank
  if (nrow(found) > 0) {
    was_found = TRUE
    ## combine sentences if they are consecutive
    # start with longest possible text
    extract_text = str_sub(
      intext,
      found[1, 1] - 180,
      found[nrow(found), 2] + 180
    ) # add 180 characters either side to get full sentence
    # now split into sentences using full-stops
    sentences = str_split(extract_text, pattern = '\\. ')[[1]]
    index = str_detect(sentences, in_pattern) # which sentences have mentions
    # find longest string of consecutive sentences with mentions
    long = rle(index)
    index2 = which(long$values == TRUE) #
    long_run = long$lengths[index2] # longest run (integer)
    delta = c(FALSE, diff(index))
    sentences_to_pick = NULL
    for (k in seq(long_run)) {
      this_index = which(cumsum(index) == k)[1]
      sentences_to_pick = c(sentences_to_pick, this_index)
    }
    #
    extract_text = paste(
      paste(sentences[sentences_to_pick], collapse = '. ', sep = ''),
      '.',
      sep = ''
    ) # add full-stops
  }

  #
  #if(extract_text==''){extract_text = NA}
  to.return = data.frame(was_found = was_found, extract_text = extract_text)
  return(to.return)
} # End of function

# altmetric function from https://github.com/karthik/rAltmetric/blob/master/R/metrics.R
# without stop
# Oct 2017
altmetrics <-
  function(
    oid = NULL,
    id = NULL,
    doi = NULL,
    pmid = NULL,
    arxiv = NULL,
    isbn = NULL,
    uri = NULL,
    apikey = getOption('altmetricKey'),
    foptions = list(),
    ...
  ) {
    if (is.null(apikey)) {
      apikey <- '37c9ae22b7979124ea650f3412255bf9'
    }

    acceptable_identifiers <- c("doi", "arxiv", "id", "pmid", "isbn", "uri")
    # If you start hitting rate limits, email support@altmetric.com
    # to get your own key.

    if (all(sapply(list(oid, doi, pmid, arxiv, isbn, uri), is.null))) {
      stop(
        "No valid identfier found. See ?altmetrics for more help",
        call. = FALSE
      )
    }

    # If any of the identifiers are not prefixed by that text:
    if (!is.null(id)) {
      id <- prefix_fix(id, "id")
    }
    if (!is.null(doi)) {
      doi <- prefix_fix(doi, "doi")
    }
    if (!is.null(isbn)) {
      isbn <- prefix_fix(isbn, "isbn")
    }
    if (!is.null(uri)) {
      uri <- prefix_fix(uri, "uri")
    }
    if (!is.null(arxiv)) {
      arxiv <- prefix_fix(arxiv, "arXiv")
    }
    if (!is.null(pmid)) {
      pmid <- prefix_fix(pmid, "pmid")
    }

    # remove the identifiers that weren't specified
    identifiers <- ee_compact(list(oid, id, doi, pmid, arxiv, isbn, uri))

    # If user specifies more than one at once, then throw an error
    # Users should use lapply(object_list, altmetrics)
    # to process multiple objects.
    if (length(identifiers) > 1) {
      stop(
        "Function can only take one object at a time. Use lapply with a list to process multiple objects",
        call. = FALSE
      )
    }

    if (!is.null(identifiers)) {
      ids <- identifiers[[1]]
    }

    supplied_id <-
      as.character(as.list((strsplit(ids, '/'))[[1]])[[1]])

    # message(sprintf("%s", supplied_id))
    if (!(supplied_id %in% acceptable_identifiers)) {
      stop(
        "Unknown identifier. Please use doi, pmid, isbn, uri, arxiv or id (for altmetric id).",
        call. = F
      )
    }
    base_url <- "http://api.altmetric.com/v1/"
    args <- list(key = apikey)
    request <-
      httr::GET(paste0(base_url, ids), query = args, foptions)
    if (httr::status_code(request) == 404) {
      cat("No metrics found for object")
    } else {
      httr::warn_for_status(request)
      results <-
        jsonlite::fromJSON(httr::content(request, as = "text"), flatten = TRUE)
      results <- rlist::list.flatten(results)
      class(results) <- "altmetric"
      results
    }
  }


#' @noRd
prefix_fix <- function(x = NULL, type = "doi") {
  if (is.null(x)) {
    stop("Some identifier required")
  }

  # Check for arXiv and arxiv
  type2 <- tolower(type)
  val <- c(grep(type, x), grep(type2, x))

  if (any(val == 1)) {
    # lose the prefix and grab the ID
    id <- strsplit(x, ":")[[1]][2]
    res <- paste0(tolower(type), "/", id)
  } else {
    res <- paste0(tolower(type), "/", x)
  }
  res
}

altmetric_data <- function(alt_obj) {
  if (inherits(alt_obj, "altmetric")) {
    res <- data.frame(t(unlist(alt_obj)), stringsAsFactors = FALSE)
  }
  res
}

#' @noRd
ee_compact <- function(l) {
  Filter(Negate(is.null), l)
}


## function to add confidence intervals to table using the Wilson method
add_intervals = function(intable, N, method = 'wilson') {
  table = mutate(
    intable,
    lower = binom.confint(x = n, n = N, methods = method)$lower, # add confidence interval
    upper = binom.confint(x = n, n = N, methods = method)$upper
  ) %>%
    mutate(
      lower = ifelse(n == N, NA, lower), # remove intervals for total column
      upper = ifelse(n == N, NA, upper)
    )
  return(table)
}

# slight modification to str_replace function
# changing files that have _ to get actual doi with /
str_replace_doi = function(x) {
  book_chapters = c(
    '10.1007.978-3-030-59861-7.45(\\.pdf)?',
    '10.1007.978-3-031-21881-1.9(\\.pdf)?'
  )
  odd_pattern = paste(book_chapters, collapse = '|')
  if (!str_detect(x, odd_pattern)) {
    y = str_replace_all(x, '_', '/')
    return(y)
  }
  if (str_detect(x, book_chapters[1])) {
    y = '10.1007/978-3-030-59861-7_45' # second underbar must remain
  }
  if (str_detect(x, book_chapters[2])) {
    y = '10.1007/978-3-031-21881-1_9' # second underbar must remain
  }
  return(y)
}

## function to tabulate agreement
# called by 6_ra_agreement.Rmd
function_agree = function(ra_one, ra_two, varname) {
  error = NULL
  # rename
  index = which(names(ra_one) == varname)
  names(ra_one)[index] = 'r1'
  index = which(names(ra_two) == varname)
  names(ra_two)[index] = 'r2'
  #
  combine = left_join(ra_two, ra_one, by = 'doi')
  if (nrow(combine) != 20) {
    error = 'yes'
  }

  # make sure all levels in both (only using the random sample, otherwise there are too many levels)
  l1 = unique(combine$r1)
  l2 = unique(combine$r2)
  levels = unique(c(l1, l2))
  levels = levels[order(levels)]
  combine = mutate(
    combine,
    r1 = factor(r1, levels = levels),
    r2 = factor(r2, levels = levels)
  )

  # make table
  tab = tabyl(combine, r1, r2)
  names(tab)[1] = ' '
  # agreement
  agree = gwet.ac1.table(tab[, -1])
  # table
  ftab = flextable(tab) %>%
    theme_apa() %>%
    colformat_double(digits = 0) %>%
    fontsize(part = 'all', size = 9) %>%
    autofit()

  # list differences
  diffs = filter(combine, r1 != r2)
  if (any(str_detect(pattern = '^comment', names(combine))) == TRUE) {
    diffs = rename(
      diffs,
      'RA1' = 'r1',
      'comment.RA1' = 'comment.y',
      'RA2' = 'r2',
      'comment.RA2' = 'comment.x'
    ) %>%
      select('doi', 'comment.RA1', 'RA1', 'comment.RA2', 'RA2')
  }
  if (any(str_detect(pattern = '^comment', names(combine))) == FALSE) {
    diffs = rename(diffs, 'RA1' = 'r1', 'RA2' = 'r2') %>%
      select('doi', 'RA1', 'RA2')
  }
  dtab = flextable(diffs) %>%
    theme_apa() %>%
    colformat_double(digits = 0) %>%
    fontsize(part = 'all', size = 9) %>%
    autofit()

  # return
  to.return = list()
  to.return$table = ftab # return
  to.return$agree = agree
  to.return$error = error
  to.return$diffs = dtab
  return(to.return)
}

# function for bland-altman
# called by 6_ra_agreement.Rmd
bland_altman = function(ra_one, ra_two, varname) {
  error = NULL
  # rename
  index = which(names(ra_one) == varname)
  names(ra_one)[index] = 'r1'
  index = which(names(ra_two) == varname)
  names(ra_two)[index] = 'r2'
  #
  combine = left_join(ra_two, ra_one, by = 'doi') %>%
    mutate(mean = (r1 + r2) / 2, diff = r1 - r2)
  # calculate limits of agreement
  loa = summarise(
    combine,
    mean = mean(diff, na.rm = TRUE),
    z = qnorm(0.975),
    sd = sd(diff, na.rm = TRUE),
    lower = mean - (z * sd),
    upper = mean + (z * sd)
  )
  #
  plot = ggplot(combine, aes(x = mean, y = diff)) +
    geom_point(col = 'dodgerblue') +
    geom_hline(data = loa, aes(yintercept = lower), lty = 2, col = 'darkred') +
    geom_hline(data = loa, aes(yintercept = upper), lty = 2, col = 'darkred') +
    geom_hline(lty = 1, yintercept = 0) +
    xlab('Mean') +
    ylab('Difference (RA1 minus RA2)') +
    theme_bw() +
    theme(panel.grid.minor = element_blank())

  # list differences (include where one is missing and other is not)
  diffs = filter(
    combine,
    (r1 != r2) | (is.na(r1) & !is.na(r2)) | (!is.na(r1) & is.na(r2))
  ) %>%
    select(doi, r1, r2)

  # return
  to.return = list()
  to.return$plot = plot
  to.return$loa = loa
  to.return$diffs = diffs
  return(to.return)
}


## From Sainani et al
# function to find stats department
find_stats_department = function(this_doi) {
  departments = c(
    'statistic(s|al)',
    'data science',
    'data analytics',
    'epidemiology',
    'mathematics',
    'maths',
    'computer science',
    'computers',
    'economics',
    'datalys center'
  ) # 'biostatistics'
  departments = paste(departments, collapse = '|')
  this_paper = oa_fetch(
    doi = this_doi,
    entity = "works",
    api_key = my_open_alex_key,
    mailto = 'a.barnett@qut.edu.au',
    options = list(select = c('id', 'doi', 'authorships'))
  )
  # if empty
  if(length(this_paper)==0){
    frame = data.frame(doi = this_doi, statistician = NA)
    return(frame)
  }
  # if there is a result
  to_search = this_paper$authorships[[1]]
  match = any(str_detect(
    tolower(to_search$affiliation_raw),
    pattern = departments
  ))
  frame = data.frame(doi = this_doi, statistician = match)
  return(frame)
}
