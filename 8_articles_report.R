# 8_articles_report.R
# create the main report
# Feb 2026
library(rmarkdown)

# main report
render(
  input = "8_articles_report.Rmd",
  output_format = 'word_document',
  output_dir = 'reports', # put Word file into separate reports directory
  output_file = "8_articles_report.docx"
)

# appendix
render(
  input = "8_articles_report_appendix.Rmd",
  output_format = 'word_document',
  output_dir = 'reports', # put Word file into separate reports directory
  output_file = "8_articles_report_appendix.docx"
)
