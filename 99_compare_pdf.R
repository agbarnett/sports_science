# 99_compare_pdf.R
# compare comment and PDF files
# sourced by 5_read_pdf_comments_by_RA.R
# November 2025

files_comment = dir('data/pdf_comments', pattern='\\.xfdf$') # 
files_pdf = dir('data/pdfs', pattern='\\.pdf$') # 
files_comment = str_remove(files_comment, '\\.xfdf$')
files_pdf = str_remove(files_pdf, '\\.pdf$')

#
any(!files_pdf%in%files_comment)
any(!files_comment%in%files_pdf)

# these are PDFs that are missing comments:
index = which(!files_pdf%in%files_comment)
files_pdf[index] # should be empty

# this is the excluded file (I did not delete comments): "10.1249_jes.0000000000000336"
index = which(!files_comment%in%files_pdf)
files_comment[index] # should be empty

# from 
load('data/4_combined_papers.RData')
pdoi = papers$doi
pdoi = str_replace_all(pdoi, '/', '_')
pdoi %in% files_comment
files_comment[!files_comment %in% pdoi]
# "10.1016_j.cophys.2019.05.009"