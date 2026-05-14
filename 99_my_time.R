# 99_my_time.R
# plot my time spent on the project 
# May 2026
library(rmarkdown)

render(input = "99_my_time_report.Rmd",
       output_format = 'word_document',
       output_dir = 'checks', # into separate checks directory
       output_file = "99_my_time.docx")
