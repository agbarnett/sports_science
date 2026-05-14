# 8_flowchart.R
# flow chart of included and excluded papers
# October 2025
library(dplyr)
library(diagram)
library(readxl)

## Numbers do not currently add up, but should for final version

## How many were checked by Alex (these are Excel files sent to Alex)
r1 = read_xlsx('data/3_papers.xlsx', sheet=1)
n_1 = nrow(r1)
r2 = read_xlsx('data/3_papers_extra.xlsx', sheet=1)
n_2 = nrow(r2)
r3 = read_xlsx('data/3_papers_extra_two.xlsx', sheet=1)
n_3 = nrow(r3)
#
sent_dois = c(r1$doi, r2$doi, r3$doi)
any(duplicated(sent_dois))
cat("RA checked", n_1+n_2+n_3,'\n')

## Exclusions; from 4_exclude.R
load('data/4_combined_papers.RData')
remove(papers) # avoid overlap with 1_read_ais_papers.R
## excluded by Alex and/or Paolo after reading
n_excluded = length(dois_to_exclude)

## Database search results
# from 1_search_pubmed.R, 1_read_ais_papers.R and 1_search_scopus.R
# pubmed
load('data/1_pubmed_papers.RData')
pubmed = mutate(data, doi = tolower(doi)) 
n_pubmed = nrow(pubmed)
load('data/1_scopus_papers.RData')
scopus = mutate(scopus, doi = tolower(doi)) 
n_book_chapters = filter(scopus, is.na(doi)) %>%
  nrow()
# scopus
scopus = filter(scopus, !is.na(doi)) # remove book chapters
n_scopus = nrow(scopus)
# AIS search
load('data/1_articles.RData') # from AIS search
papers = unique(papers)
n_pre_2000 = filter(papers, year < 2020) %>% nrow()
papers = filter(papers, year >=2020)
n_removed_conference_ais = filter(papers, is.na(doi)) %>% # remove conference abstracts
  nrow()
papers = filter(papers, !is.na(doi)) # remove book chapters
n_ais = nrow(papers)

# reported by Alex
n_non_english = 1

# count duplicates
pubmed_doi_only = select(pubmed, doi)
scopus_doi_only = select(scopus, doi)
papers_doi_only = select(papers, doi)
n_unique = full_join(pubmed_doi_only, scopus_doi_only, by = 'doi') %>%
  full_join(papers_doi_only, by='doi') %>%
  unique() %>%
  nrow()
n_unique = n_unique - n_non_english
n_duplicates = (n_ais + n_scopus + n_pubmed) - n_unique


# final included number (good triangulation test)
load('data/7_analysis.RData') # from 7_combine_data.R
n_included = nrow(papers)


# labels
l1 = paste('Search numbers\nScopus (N=',  n_scopus, ')', sep='') 
l2 = paste('Search numbers\nPubMed (N=',  n_pubmed, ')', sep='') 
l3 = paste('Search numbers\nAIS (N=',  n_ais, ')', sep='') 
l4 = paste('Combined (N=', n_ais + n_scopus + n_pubmed, ')', sep='') # 
l5 = paste('Excluded\nduplicates (N=', n_duplicates, ')', sep='') # 
l6 = paste('Excluded\nnon-English (N=', n_non_english, ')', sep='') # 
l7 = paste('Checked by research\nassistant (N=', n_unique, ')', sep='') # 
l8 = paste('Excluded\nno AIS authors or\nnon-article (N=', n_excluded, ')', sep='') # 
l9 = paste('Included (N=', n_included, ')', sep='') # 
null = ''
labels = c(l1, l2, l3, l4, l5, l6, l7, l8, l9, null, null, null)
n.labels = length(labels)

# cross-check of numbers
excluded = length(dir('data/pdfs/excluded', pattern = '\\.pdf$')) # how many excluded
excluded = excluded + 6 + 1 # excluded that could not be downloaded (6 book chapters, 1 correction)
included = length(dir('data/pdfs', pattern = '\\.pdf$')) # how many in cluded

#
### make data frame of box chars
# box.prop = length/width ratio, so > 1 = tall and thin
frame = read.table(sep='\t', stringsAsFactors=F, skip=0, header=TRUE, text='
i	x	y	box.col	box.type	box.prop	box.size
1	0.2	0.94	white	square	0.33	0.13
2	0.5	0.94	white	square	0.33	0.13
3	0.8	0.94	white	square	0.33	0.13
4	0.5	0.75	white	square	0.33	0.13
5	0.8	0.65	white	square	0.34	0.13
6	0.8	0.5	white	square	0.34	0.13
7	0.5	0.4	white	square	0.34	0.13
8	0.8	0.3	white	square	0.34	0.13
9	0.5	0.15	white	square	0.34	0.13
10	0.5	0.65	transparent	square	0.0001	0.0001
11	0.5	0.3	transparent	square	0.0001	0.0001
12	0.5	0.5	transparent	square	0.0001	0.0001
')
# positions:
pos = as.matrix(subset(frame, select=c(x, y)))
# joins between boxes
M = matrix(nrow = nrow(frame), ncol = nrow(frame), byrow = TRUE, data = 0)
M[4, 1] = "' '"
M[4, 2] = "' '"
M[4, 3] = "' '"
M[7, 4] = "' '"
M[9, 7] = "' '"
M[5, 10] = "' '" # exclude arrow
M[8, 11] = "' '" # exclude arrow
M[6, 12] = "' '" # exclude arrow
# colours
tcol = rep('black', nrow(frame))

## make figure 
jpeg('figures/8_flow_diagram.jpg', width=7.5, height=7, units='in', res=400, quality = 100)
par(mai=c(0,0.04,0.04,0.04))
plotmat(M, pos = pos, name = labels, lwd = 1, shadow.size=0, curve=0, arr.pos = 0.45,
        box.lwd = 2, cex.txt = 1, box.size = frame$box.size, box.col=frame$box.col,
        box.type = frame$box.type, box.prop = frame$box.prop, txt.col = tcol)
dev.off()

