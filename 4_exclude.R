# 4_exclude.R
# exclude papers that are not from AIS or are commentaries, etc; found by research assistant
# also moved PDFs into subfolder of 'excluded'
# October 2025
library(dplyr)
library(stringr)

# papers from 2_compare_combine_databases.R; starting with 355 papers
load('data/2_combined_papers.RData')
n_start = nrow(papers)

# list of DOIs
dois_to_exclude = c(
  "10.1038/s41467-020-16819-z", # Not a sports article
  "10.3389/fspor.2021.681766", # Corrigendum
  '10.1016/j.jsams.2020.03.014', # not an Australian Institute of Sport article
  '10.3390/jcm13144171', # not AIS
  '10.1186/s12889-019-8049-6', # not AIS
  '10.1016/j.ptsp.2024.03.004', # not AIS
  '10.1007/s40279-022-01776-y', # correction
  '10.1016/j.cophys.2019.05.009', # from 2019
  '10.1123/jpah.2024-0174', # Australian Sports Commission
  '10.1016/b978-0-12-818460-8.00006-x', # letter to the editor
  '10.4324/9781003321286-8',
  '10.4324/9781003321286-30',
  '10.4324/9781003184430-12',
  '10.4324/9781003321286-14',
  '10.4324/9781003321286-24',
  '10.4324/9781003366140-18',
  '10.1123/ijspp.2019-0561', # brief report
  '10.1136/bjsports-2019-100707', # editorial
  '10.1007/978-3-030-59861-7_45', #conference article
  '10.1024/2674-0052/a000006', # is only a 2 page long article
  '10.1249/jes.0000000000000336', # only Australian sports commission authors
  '10.1519/jsc.0000000000003937', # not AIS
  '10.1007/978-3-031-21881-1_9', # book chapter
  '10.33155/j.ramd.2020.11.004', # not in English
  '10.3390/s22083090', # SA institute of sport
  '10.1080/14763141.2021.1900356',
  '10.1080/02640414.2020.1857105',
  '10.1080/17461391.2022.2079425',
  '10.1080/17461391.2021.1880648',
  '10.1519/jsc.0000000000004229',
  '10.1016/j.physbeh.2023.114104',
  '10.1080/1750984x.2021.1977974',
  '10.1016/j.jsams.2019.12.026',
  '10.1123/ijspp.2023-0496',
  '10.1080/24733938.2022.2159061',
  '10.3389/fnins.2022.937086',
  '10.1519/jsc.0000000000004858',
  '10.1080/02640414.2024.2400816',
  '10.1080/17461391.2020.1771430',
  '10.1080/24748668.2021.1933846',
  '10.1080/17461391.2021.1963844',
  '10.1080/14763141.2021.1974532',
  '10.2478/ijcss-2021-0004',
  '10.1519/jsc.0000000000004729',
  '10.5114/biolsport.2022.103572',
  '10.5114/jhk/185442',
  '10.1080/17461391.2022.2150896',
  '10.3389/fphys.2020.614765',
  '10.1080/17461391.2021.1977393',
  '10.1123/ijspp.2023-0497',
  '10.1519/jsc.0000000000004057',
  '10.1002/ejsc.12203',
  '10.3389/fimmu.2020.02167',
  '10.3390/bios11060185',
  '10.1080/17461391.2021.1922504',
  '10.1016/j.jsams.2023.09.006',
  '10.1080/17461391.2023.2224285',
  '10.1123/ijspp.2019-0313',
  '10.1519/jsc.0000000000004534',
  '10.1007/s40279-023-01874-5',
  '10.52082/jssm.2024.1',
  '10.1080/02640414.2024.2369353',
  '10.1186/s40798-021-00301-1',
  '10.1080/17461391.2022.2085631',
  '10.1080/17461391.2021.2006800',
  '10.52082/jssm.2023.133',
  '10.1080/24748668.2024.2386839',
  '10.1055/a-2211-0813',
  '10.3390/s21103571'
)
cat("There are ", length(dois_to_exclude), ' papers to exclude.\n', sep = '')

# remove
papers = filter(papers, !doi %in% dois_to_exclude)
n_exclude_manual = n_start - nrow(papers) # how many were excluded

# save
save(papers, dois_to_exclude, file = 'data/4_combined_papers.RData')

## check that all remaining PDFs have a comment file
pdfs = dir('data/pdfs', pattern = 'pdf$') %>% str_remove_all('\\.pdf')
comments = dir('data/pdf_comments/', pattern = 'xfdf$') %>%
  str_remove_all('\\.xfdf')
setdiff(pdfs, comments) # should be empty; non empty means there are comment files missing
# any excluded PDFs not moved out of main folder:
dois_to_check = str_replace_all(dois_to_exclude, '/', '_')
intersect(pdfs, dois_to_check) # should be empty

## compare paper numbers with files
from_papers = pull(papers, doi)
from_papers = str_replace_all(from_papers, '/', '_')
setdiff(from_papers, pdfs)

# find XML files that should be deleted from the folder
xmls = dir('xml', pattern = 'xml$')
length(xmls)
xmls_to_check = str_remove(xmls, '\\.xml$')
setdiff(xmls_to_check, pdfs) # should be empty


#### flow diagram ####
library(diagram)
attach(flow_numbers) # from 2_compare_combine_databases.R
n_final = nrow(papers) # update final numbers
l1 = paste0('PubMed = ', n_pubmed)
l2 = paste0('Scopus = ', n_scopus)
l3 = paste0('AIS information\nofficer = ', n_library)
l4 = paste0('Combined = ', n_combined)
l5 = paste0(
  'Excluded\nDuplicate = ',
  n_duplicates,
  '\nNo AIS affiliation = ',
  n_exclude,
  '\nAfter manual checking = ',
  n_exclude_manual
)
l6 = paste0('Final sample = ', n_final)
null = '' # for arrow placements
labels = c(l1, l2, l3, l4, l5, l6, null)
n.labels = length(labels)
### make data frame of box chars
frame = read.table(
  sep = '\t',
  stringsAsFactors = F,
  skip = 0,
  header = T,
  text = '
i	x	y	box.col	box.type	box.prop	box.size
1	0.2	0.94	white	square	0.35	0.14
2	0.5	0.94	white	square	0.35	0.14
3	0.8	0.94	white	square	0.35	0.14
4	0.25	0.5	white	square	0.35	0.14
5	0.75	0.25	white	square	0.35	0.24
6	0.25	0.06	white	square	0.35	0.15
7	0.25	0.25	transparent	square	0	0'
)
pos = as.matrix(subset(frame, select = c(x, y)))
M = matrix(nrow = n.labels, ncol = n.labels, byrow = TRUE, data = 0)
M[4, 1] = "' '"
M[4, 2] = "' '"
M[4, 3] = "' '"
M[6, 4] = "' '"
M[5, 7] = "' '"

jpeg(
  'figures/4_consort_flow.jpg',
  width = 5,
  height = 5,
  units = 'in',
  res = 500,
  quality = 100
)
par(mai = c(0, 0.04, 0.04, 0.04))
plotmat(
  M,
  pos = pos,
  name = labels,
  lwd = 1,
  shadow.size = 0,
  curve = 0,
  box.lwd = 2,
  cex.txt = 1,
  box.size = frame$box.size,
  box.col = frame$box.col,
  box.type = frame$box.type,
  box.prop = frame$box.prop,
  txt.col = 'black'
)
dev.off()

# manual check of numbers
# 790 - 431 - 4 - 68
