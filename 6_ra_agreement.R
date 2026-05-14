# 6_ra_agreement.R
# create the report that looks at the agreement between RAs
# Feb 2026
library(rmarkdown)

render(input = "6_ra_agreement.Rmd",
       output_format = 'word_document',
       output_dir = 'checks', # into separate checks directory
       output_file = "6_ra_agreement.docx")
