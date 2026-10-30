# Data for the AIS audit

The numbers at the start of the file name correspond to the R code files and are in execution order. Files are in R format (RData) or Excel.


* `1_articles.RData` = read the papers from the AIS from `1_read_ais_papers.R`
* `1_pubmed_papers.RData` = search research from PubMed from `1_search_pubmed.R`
* `1_scopus_papers.RData` = search research from Scopus from `1_search_scopus.R`

~

* `2_combined_papers.RData` = combine the three sources of papers from `2_compare_combine_databases.R`

~

* `3_papers.xlsx` = papers for checking by the Research Assistants from `3_export_excel.R`
* `3_papers_extra.xlsx` = papers for checking by the Research Assistants (second batch) from `3_export_excel.R`
* `3_papers_extra_two.xlsx` =  papers for checking by the Research Assistants (third batch) from `3_export_excel.R`
* `3_papers_ran_check.xlsx` = papers for validation from `3_export_excel.R`

~

* `4_combined_papers.RData` = remaining papers after exclusions from  `4_exclude.R`

~

* `5_altmetric.RData` = Altmetric data for all papers from `5_get_altmeric.R`
* `5_oddpub.RData` = Data on open data/code using oddpub from `5_data_code_oddpub.R`
* `5_open_alex.RData` = Data extracted from OpenAlex for all papers from `5_open_alex.R`
* `5_audit.RData` = data entered by the research assistant from `5_read_pdf_comments_by_RA.R`
* `5_audit_check.RData` = research assistant validation from `5_read_pdf_comments_by_RA.R`
* `5_audit_check2.RData` = research assistant validation (second batch) from `5_read_pdf_comments_by_RA.R`
* `5_audit_pre_fix.RData` = data entered by the research assistant from `5_read_pdf_comments_by_RA.R`; version before fixing minor data errors which is needed for the validation checks
* `5_automated.RData` = Data automatically collected from PDFs/XMLS from `5_read_pdf_files_to_xml_automate.R`
* `5_interpretation_[...].xlsx` = Data on the interpretation of the study results (multiple Excel files)

~

* `6_interpretation.RData` = combined data set on the interpretation of the study results from ``

~

* `7_analysis.RData` = main analysis data from `7_combine_data.R`
* `7_analysis.xlsx` = main analysis data in Excel format, separate sheet for each question `7_combine_data.R`
* `data_dictionary.docx` = data dictionary for analysis files

~

* `99_data_collection.xlsx` = summary of the colleced data from `99_data_collection_summary.R`
* `Published AIS Research articles list 2000-2024 (Paolo Menaspa).xlsx` = Potential papers provided by AIS used by `1_read_ais_papers.R`


Subfolder:

* `pdf_comments` comments made on the PDFs of the journal articles in xfdf format