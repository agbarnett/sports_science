# R code for searching bibliographic databases and finding the papers for the AIS audit

Research conducted with the Australian Institute of Sport (AIS) on statistical thinking.

The code below is for an audit of published papers supported by the AIS. The PDFs were checked by a research assistant. Other features of the papers were extracted using automated screening.

Key R packages:
* `roadoi` for checking Open Access status
* `paperfile` for converting the PDFs to XML
* `[oddpub](https://github.com/quest-bih/oddpub)` for checking open data and code

Code:

* `1_affiliations.R` = list of relevant affiliations
* `1_read_ais_papers.R` = read AIS papers from the search done by the AIS
* `1_search_pubmed.R` = search pubmed for AIS papers
* `1_search_scopus.R` = search scopus for AIS papers

* `2_compare_combine_databases.R` = compare the papers found by: pubmed, scopus, the excel sheet provided by the AIS library, then combine the best sources

* `3_export_excel.R` = export papers to Excel

* `4_exclude.R` = exclude papers that are not AIS papers or are corrections, etc

* `5_open_alex.R` = get bibliographic data from _OpenAlex_ for every paper
* `5_get_altmeric.R` = get _Altmetic_ for every paper
* `5_make_altmetric_links.Rmd` = Makes a list of _Altmetric_ links for more detailed checked
* `5_read_pdf_files_to_xml_automate.R` = Read PDF papers and automate parts of the audit using XML code
* `5_read_pdf_comments_by_RA.R` = Read and process PDF comments added by the research assistant
* `5_data_code_oddpub.R` = open data and code using `oddpub`

* `6_read_interpretation.R` = read the interpretations for question 14
* `6_ra_agreement.Rmd` = report on agreement between raters in extracting data from papers
* `6_statisticians_bmj_data.R` = extracting data from the BMJ on job titles including statisticians (not used)

* `7_combine_data.R` = combine the data sources ready for analysis

* `8_articles_report.Rmd` = Main report with descriptive statistics.
* `8_wordcloud.R` = Word cloud from paper titles
* `8_author_network.R` = Plot of author network (not used)
* `8_flowchart.R` = Flow chart of included papers

* `99_functions.R` = specific functions 
* `99_patterns.R` = regex patterns for the automated searching of text from AIS papers


Subfolders:

* `data` search results and analysis data in Excel and R format, includes a subfolder of `comments` with the research assistant's comments on each paper
* `figures` figures 
* `included_papers` list of the included papers
* `reports` final reports
* `checks` data checks
* `xml` papers in XML format (not shared due to paywall restrictions)
* `pdf` folder used by oddpub (not shared due to paywall restrictions)
