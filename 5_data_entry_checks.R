# 5_data_entry_checks.R
# Output random checks for each question to a Word file
# August 2025

# all this file does is run the markdown
rmarkdown::render(input = "5_data_entry_checks.Rmd",
                  output_format = 'word_document',
                  output_dir = 'checks', # into separate results directory
                  output_file = "5_data_entry_checks.docx")
