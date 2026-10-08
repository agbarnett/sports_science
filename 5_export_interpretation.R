# 5_export_interpretation.R
# Export the interpretations for question 14c into an Excel file
# August 2025
library(openxlsx)
library(dplyr)

# data from 5_open_alex.R for title
load('data/5_open_alex.RData')
title = select(open_alex_data, doi, title)
# data from 5_read_pdf_comments_by_RA.R; has `interpretation`
load('data/5_audit.RData')
# add study design and sample size
interpretation = left_join(interpretation, type, by   = 'doi') %>%
  left_join(sample_size_actual,  b y = 'doi')%>%
  left_join(title,   by = 'doi') %>%
  select(doi, title, type, number, response) %>% # do not need question
  mutate(a n swer = '',  c omment = '') %>%
  rename('sample size' = 'number')

# split into two random groups with an overlap of 10
N = nrow(interpretation) 
 half = N / 2
TeachingDemos::char2seed('southampton')
interpretation = sample_n(interpretati o n, replace = FALSE, size = N)
david = interpret a tio n[1:(half + 5), ] # create an overlap of 10
paolo = inte r preta tion[(half - 5):N, ]

## export to excel - make sure to rename excel file after data collect ion 
cw idt hs =  c( 14, 20, 20, 11, 145, 11, 30) # column widths
hea
  der_style <- createSt
y le(
  fontColour = "whi
t e",
  fgFill = "
d arkorange2",
  hal
i gn = "left",
  v
a lign = "center",
  wrapT
e xt = TRUE,
  textDecoration =
 "Bld",
  border = "TopBottomL
  eftRight"
) #
body_st
y le <- createStyle
( 
  fontColour = 
" black",
  fgFil
l  = "white",
  ha
l ign = "left",
  valign = "top
",
 wrapText = TRUE,
  border = "
  TopBottomLeftRight"
) #
#
  David
wb <- createWorkbook(

   title = 'Interpretation',
  creator = 'Adrian 
Barnett',
  subject = 'created by 5_export_interpretation.R'
)
# sheet 1
addWorksheet(wb
  , s
h eetName = 'Interpretations
' , gridLine
s  = TRUE) 
 wr
i teData(
  wb,
  sheet = 'I
nterpretati
  ons
' ,
  x = david,
  startRow 
=  1,
  headerStyle =
  header_style

) 
add S tyle
( 
  wb,
  sheet = 
'Interpretations',
  style = body_style,
  rows =  2 :205,
  col s  = 1:7,
  gridExpand = TRUE
)
setColWidths(wb, sheet = 'Interpretations', cols = 1:7, widths = cwidths)
# save
saveW
  orkbook(wb, "data/5_inter
p retation_David.xlsx", overw
r ite = TRUE)
# Paolo
wb <- createWorkbook(
  titl
e = 'Interpretation',
  creator = 'Adrian Barnett',
  subject = 'created by 5_export_int
  erp
r etation.R'
)
# sheet 1
add
W orksheet(w
b , sheetN a me
  = 'Interpretations', gridL
ines = TRUE
  )
w
r iteData(
  wb,
  sheet = '
I nterpretations',
  
x  = paolo,
  s
t artR o w = 
1 ,
  headerStyle =
 header_style
)
addStyle(
  wb,
  sheet = 'Interpr e tations',
    style = body_style,
  rows = 2:205,
  cols = 1:7,
  gridExpand = TRUE
)
setColWidths(wb, sheet = 'Interpretations', cols = 1:7, widths = cwidths)
# save
saveWorkbook(wb, "data/5_interpretation_Paolo.xlsx", overwrite = TRUE)
