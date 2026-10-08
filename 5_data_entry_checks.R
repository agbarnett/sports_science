# 5_data_entry_checks.R
# Output random checks for each question to a Word file
# all this file does is run the markdown
# Sep 2026

# first check
rmarkdown::render(input = "5_data_entry_checks.Rmd",
                  output_format = 'word_document',
                  output_dir = 'checks', # into separate results directory
                  output_file = "5_data_entry_checks.docx")

# second check
rmarkdown::render(input = "5_data_entry_checks_2nd.Rmd",
                  output_format = 'word_document',
                  output_dir = 'checks', # into separate results directory
                  output_file = "5_data_entry_checks_2nd.docx")
