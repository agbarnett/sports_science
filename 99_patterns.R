# 99_patterns.R
# regex patterns for the automated searching of text from AIS papers
# October 2025

## open code and data done by oddpub

## software (from DB's list)
software_words = c(
  '\\br.?studio\\b',
  '\\bspss(.|v[1-9][0-9])?\\b', # optional any character for copyright; and version without break
  '\\bsas\\b',
  '\\bmatlab\\b',
  '\\bjmp\\b',
  '\\bstata\\b',
  '\\bm.?plus\\b',
  '\\bgraph.?pad.?(prism)?\\b',
  '\\bprism,?.version\\b',
  '\\bwin.?bugs\\b',
  '\\brev.?man\\b',
  '\\bminitab\\b',
  '\\bpasw\\b',
  '\\bnsolver\\b',
  '\\bjamovi\\b',
  '\\beasymedstat\\b',
  '\\bsigmaplot\\b',
  '\\bspike.?2\\b',
  '\\bmbi spreadsheets?',
  '\\bbioestat\\b',
  '\\bmedcalc\\b',
  '\\bmlwin\\b',
  '\\lisrel\\b',
  'microsoft.?excel',
  'comprehensive meta.?analysis (software|.?version)',
  '\\bnvivo\\b',
  '\\bstatistica\\b'
)
software_pattern = paste(software_words, collapse = '|')

## ethical approval text
ethical_words = c(
  'ethic(|s|al) approv(al|ed)', # also covers `was not required`
  'ethic(|s|al) (clearance|compliance|statement)', # also covers `was not required`
  'ethic(s|al) was not',
  '^ethic(s|al)( declaration| statement)$', # for section heading
  'declaration of helsinki',
  'helsinki declaration',
  'informed consent (statement)?',
  'research integrity and ethic(s|al)',
  'exempt from (a )?human ethic(s|al)',
  '(did|does|do) not require ethic(|s|al)',
  'ethic(|s|al) (governance|review )?board',
  'institution(al)? review boards?',
  'research ethics boards?',
  'human (research )?ethic(s|al) committees?',
  'research ethics commitees?.? approval', # added on Sep 2026
  'independent ethic(s|al) committees?',
  'code of ethics of the (world medical association|wma)',
  '(world medical association|wma) (international )?code of medical ethics',
  '(local|research) ethic(s|al) committees?', # added `local` on sep 2026
  'approv(ed|al) by the \\b\\w+\\b ethic' # added sep 2026
)
ethical_pattern = paste(ethical_words, collapse = '|')

## funding, add 'australian sports foundation'?
funding_words = c(
  '(had|received) no (external|research|study|specific )?funding', # added specific 2026-09-15
  'funding (statement|declaration|information)',
  '^funding:',
  '^funding$', # added to capture heading on Sep 2026
  '(was|is) (supported|funded) (in part )?by (a )?grants?',
  'authors acknowledge the (ongoing )?support of',
  '(project|research|study) (was|is) (funded|awarded) (by|via)', # added Sep 2026
  'grant numbers?',
  'no funding source', # added Sep 2026
  'no source of funding', # added Sep 2026
  'industry.(co.)?fund(ed|ing)',
  # '\\b(was|is) (generously )?supported by\\b', # false positives with discussion section talking about ideas support (Sep 2026)
  '^funding$', # for section heading
  '(co.)?funding (for this (research|study|work) )?was (received|awarded) (for this (research|study|work) )?',
  '(co.)?funded by (the )?(commonwealth|australian?|national)',
  'the authors have (not )?declared (a )?specific (funding|grants?)',
  'this (research|study|work) was (supported|(co.)?funded) by',
  'no (specific )?funding was received',
  'did not receive any (specific )(grant|funding)',
  '(we )?acknowledge (the )?(generous )?((co.)?funding|support) (of|from|by)',
  'national health and medical research council',
  'australian research council',
  '(work|research|study) (was (co.)?funded by|received funding|received support)'
)
funding_pattern = paste(funding_words, collapse = '|')

## conflict of interest
conflict_words = c(
  '(conflicts?|declarations?) of (financial |competing )?interests?',
  '(no )?(financial )?conflicts? of interest to declare',
  'competing interests?',
  '^conflicts$', # for section heading
  'disclosure statements?',
  'conflict of interest statement', #
  'nor did they have a role in the (design|analysis|reporting)',
  'no role in the (design|analysis|reporting)',
  '(financial|perceived) conflicts? of interest',
  '(funding (body|bodies)|funders?) had no role',
  'appear(ed)? to influence the (research|study|work)'
)
conflict_pattern = paste(conflict_words, collapse = '|')

## protocol and analysis plan text
# `protocol` is often used for the experimental protocol, so does not work well in sports science
protocol = c(
  '(study|published|planned|trial|research) protocol',
  '^(study )?protocol$', # for section heading
  'we (used|followed|had) (a|our) (trial |planned |published |study |research )?protocol',
  'protocol for (this|our) study',
  'publicly available (study |published |planned |trial |research )?protocol'
)
protocol_pattern = paste(protocol, collapse = '|')
plan = c(
  '(statistical )?analysis plan',
  'we (used|followed|had) an? (statistical )?analysis plan',
  '(used|had) an? sap\\b',
  'analysis plan for (this|our) (study|research|paper|experiment)',
  'publicly available (sap\\b|analysis plan)'
)
plan_pattern = paste(plan, collapse = '|')

## registration words
# '\\bosf\\b', 'open science framework', # <- dropped, because can be data sharing
registration = c(
  '\\bpre.?registration\\b',
  'registered.report',
  '\\bprospero\\b', # added Sep 2026
  'aspredicted', # must be one word, otherwise is confused with phrase
  '\\banzctr\\b',
  'clinicaltrials\\.gov',
  'australian? new zealand (clinical )?trials regist(ry|ration)',
  'a protocol was (developed and )?registered' # added sep 2026
)
registration_pattern = paste(registration, collapse = '|')

# EQUATOR templates (case sensitive)
equator = c(
  'CONSORT',
  'PRISMA',
  'STROBE',
  'MOOSE',
  'STARD',
  'SQUIRE',
  'TRIPOD',
  'CHEERS', # economics
  #            'ARRIVE',# not needed
  'CHERRIES',
  #            'CODE.EHR', # not needed
  'SPIRIT',
  'PRESENT', # sport-specific
  'SAGER',
  'StaRI|STARI', # Standards for Reporting Implementation Studies (StaRI)Statement
  'AGREE',
  'ENTREQ',
  'COREQ',
  'SRQR'
)
equator_pattern = paste(equator, collapse = '|')

## Did anyone mention "National High Performance Sport Research Agenda (NHPSRA)
NHPSRA = c('national.high.performance.sport.research.agenda', 'nhpsra') # in lower case, but acronym cannot be confused with a word
NHPSRA_pattern = paste(NHPSRA, collapse = '|')

# for removing reference numbers after full stop; not needed when using XML
reference_remove = '(?<=[a-z][a-z]\\.)\\[?[1-5][0-9]?\\]? '

# search patterns used by 5_read_pdf_comments_by_RA.R for finding questions entered by RA
semi_pattern = '(?<=^Q[1-9][0-9]?(a|b|c|d)?); '
no_colon_pattern = '(?<=^Q[1-9][0-9]?(a|b|c|d)?) (?=[A-Z|a-z])'
missing_q = '^(?=[^(q|Q)])' # pattern where Q is missing at start

## for q1b: patterns based on RA's data entry
a_pattern = '^[1-9][0-9]?[0-9]? (?=(A|a)uth)' # pattern to capture author numbers
f_pattern = '(?<=rs?(,|\\.)) [1-9][0-9]?(?=( |,))' # pattern to capture position of first author
l_pattern = '(?<=(and |,|\\.)) ?[1-9][0-9]?(?= of)' # pattern to capture position of last author
t_pattern = '(?<=of )[1-9][0-9]?[0-9]?\\.?$' # pattern to capture total author numbers

## patterns for study aims (q2a)
# this first set includes goals, objectives, ets
no_aims_but_purpose = c(
  'study did have a purpose',
  'but a (purpose|goal) of (the )?(study|research)',
  '^study purpose$',
  'objectives? of research',
  'research article had goals?',
  'there (were|was) (a )?contributions?',
  'purposes of the study that were well informed',
  'statement on what the article did',
  'statement on the article was seen',
  'well (in)?formed (and clear )?purpose',
  'statements? on what the study provides',
  '.goals. that were well described',
  'statements? on what the study sought'
)
no_aims_but_purpose = paste(no_aims_but_purpose, collapse = '|')
no_aims = c(
  '^no(,| )',
  '^no$',
  'no(t a)?( specific)? research questions?',
  'aims? that (were|was) poorly formed',
  'aims but were not formed well',
  'no aims? or research questions?( seen)?',
  'no clear aims? or research questions?',
  'no clear research questions? or aims?',
  'there was no (clear )?aim'
)
no_aims = paste(no_aims, collapse = '|')
yes_aims = c(
  '^yes(,| )',
  '^yes$',
  'aims? (that )?(however )?(were|was) well formed',
  'well (in)?formed (research )?(aims?|questions?)',
  'questions that were well formed',
  '(were|was) (a )?clear aims?',
  'they (were|was) well formed',
  'there (were|was a) (clear )?defined aims?',
  'has one research aim',
  'aim was clear and well formed',
  'had a research question',
  'the research article has an aim',
  '^aim$'
)
yes_aims = paste(yes_aims, collapse = '|')


## q2c, Can the question(s) be expressed using an established framework
pico_yes = c(
  'aim could be expressed with pico',
  'can be expressed with pico',
  'pico expressed p',
  '^pico yes$',
  '^pico(\\.|,)',
  'all pico',
  '^pico$'
)
pico_yes = paste(pico_yes, collapse = '|')
#
spider_yes = c('^spider$', '^spider yes$')
spider_yes = paste(spider_yes, collapse = '|')
#
pico_partial = c(
  'pico expressed intervention, comparison and outcome',
  'pico only expressed through intervention and outcome',
  'pico aim only described by intervention and outcome',
  'p was not explicitly mentioned but overall it was clear',
  'can be expressed with ico',
  '\\bco\\b', # using breaks because of responses such as: "aim 1: spie aim 2: pie aim 3: pie"
  '\\bico\\b',
  '\\bio\\b',
  '\\bpco\\b',
  '\\bpo\\b',
  '\\bpie\\b',
  '\\bpio\\b',
  '\\bpco\\b'
)
pico_partial = paste(pico_partial, collapse = '|')
#
spider_partial = c(
  '\\bspide\\b',
  '\\bspi\\b',
  '\\bpi\\b',
  '\\bspid\\b',
  '\\bpied\\b',
  '\\bpide\\b',
  '\\bspie\\b'
)
spider_partial = paste(spider_partial, collapse = '|')
#
no_framework = c(
  'can.?not be expressed through pico or spider',
  '\\bo\\b', # just an outcome
  '^no(\\.|,)'
)
no_framework = paste(no_framework, collapse = '|')

# Q3 (previous research), had to add new category of not mentioned but justified?
not_mentioned = c(
  'not? mention(ed)? at all',
  'no previous research (were |was )?mentioned'
)
not_mentioned = paste(not_mentioned, collapse = '|')
no_justification = c(
  'no (clear )?justifications? (is |was )?(given|made)',
  'no (clear )?justifications? for (the|this)',
  'no clear previous research or justifications?',
  'nor? clear justifications?',
  'no, did not find rq',
  'no but their review',
  'lack justification on why'
)
no_justification = paste(no_justification, collapse = '|')
mentioned_but_justified = c(
  '(topics?|articles?|research|study) (was |is )?(very )?(well )?justified',
  'was mention of previous research but justification',
  'justified as previous systems (were )?could be improved',
  'this article investigated a previous study and justified',
  'previous research had a small homogeneous sample and more evidence was needed',
  'there was good research justifying this research',
  'it was justified',
  'yes, similar study but not on para swimmers and passive drag', # text from Ran
  'yes, similar topic but this study extended the scope of population',
  'yes but functional data analysis was used',
  'yes, but it was not female focused/specific',
  'yes the previous study was on athletes at all levels',
  'yes but this study improved limitations of previous',
  'yes but this is a extension for artistic gymnastics',
  'yes, but using bfpca was a first on this context',
  'yes on the same topic but it is the first time on a highly trained athlete cohort',
  'yes, they cited previous biomechanical research directly relevant to their study question',
  'yes, this study is further investigation'
)
mentioned_but_justified = paste(mentioned_but_justified, collapse = '|')
more_evidence_needed = c(
  'need for more evidence',
  'more evidence (was |is )?needed'
)
more_evidence_needed = paste(more_evidence_needed, collapse = '|')
same_population = '(previous|prior) research (were |was )?in (a )?different population'
had_flaws = '\\bflaw(ed|s)|\\berror|\\bwrong'


# Q5a for sample size
no_sample_size = c(
  '^no$',
  'not? (a )?(clear )?(sample size|calculation)',
  'no\\. note that they invited all elite para'
) # could perhaps be NA, but should still be some mention
no_sample_size = paste(no_sample_size, collapse = '|')
yes_sample_size = c(
  '^yes$',
  '^yes, ',
  'sample size (calculation )?was (completed|present|given|included)',
  'was (a )?(clear )?sample size calc',
  'sample size calculation was completed',
  'sample size power was mentioned'
)
yes_sample_size = paste(yes_sample_size, collapse = '|')

# q5b, sample size justified
size_justified = c(
  '(sample|effect) size (was |were )?justified',
  '^yes, ',
  'yes based on similar research',
  'reference of a previous study was used as justification',
  'the effect size had a reference',
  'partial least squares sem uses an iterative', # part of a longer text that had justification
  'the article did justify the sample size',
  'was a reference and justification',
  'there (was |were )(a )?justification'
)
size_justified = paste(size_justified, collapse = '|')
size_not_justified = c(
  '(sample|effect) size (was |were )?not justified',
  'no reference or justification',
  'but cited a paper', # from Ran; citing a paper alone is not sufficient justification
  'but was referenced to another study', #
  'effect size mentioned but did not justify',
  'powered to detect a moderate difference', # part of a longer text from Alex that did not have justification
  'no direct justification of the effect',
  'justified as .based on such data', # see longer text, not a good justification
  'was no clear justification',
  '^no, ',
  '^no$',
  'there (was|were|appear) no justifications?'
)
size_not_justified = paste(size_not_justified, collapse = '|')

# Q5c/Q5d, sample size
# pattern to extract number after n=
number_pattern1 = '(?<=\\bn(| )=) ?[0-9][0-9]?[0-9]?[0-9]?[0-9]?\\b' # version with n=
number_pattern2 = '\\b[0-9][0-9]?[0-9]?[0-9]?[0-9]?\\b' # just numbers
number_pattern = paste(number_pattern1, number_pattern2, sep = '|')

# Q10, missing data
missing_no = c(
  'not? (mention(ed)?|described)',
  'not reported what data',
  'no, inadequate reporting',
  'no statement',
  '^no$',
  'they just briefly mentioned',
  'discussed but was not adequately',
  'only reported as part of a summary table', # borderline?
  'i would say no',
  'greater than 50%', # looked at specific example, did not qualify as discussion of missing data as was just a mention of discarding some missing data
  'missing data were seen reported', # checked this one, very brief acknowledgement of missing data, but not enough
  'there was a statement that missing data were excluded but no clear indication of what data were excluded',
  'not? missing (data|values) (was |were )?(discussed|described|reported|mentioned)'
)
missing_no = paste(missing_no, collapse = '|')
missing_none = c(
  '^no missing data$',
  '^(there were )?not? missing data (were |was )?(found|seen) ?(to be )?(or )?(reported|mentioned)?'
)
missing_none = paste(missing_none, collapse = '|')
missing_yes = c(
  'missing (data|values) (is |are |were |was )?(well )?(mentioned|described|reported|discussed)',
  '(good|was) reporting of missing data',
  'yes, discussed and (briefly )?reported',
  'one athlete with missing data was removed and justified',
  'yes one participant removed due to missing data'
)
missing_yes = paste(missing_yes, collapse = '|')

## q11, outliers - `justifi` for justification/justified
# No outliers removed; they checked for outliers but did not identify any by their method and none removed; or they were seen but not removed (include no mention of outliers):
outliers_no = c(
  'not? outliers? (were )?(found|mentioned|seen)',
  'not? outliers? (seen |were )?reported',
  '^outliers (were )?not (discussed|mentioned)',
  'no outliers? (were )?(seen|removed) or (removed|seen)',
  'no mention of outliers being removed?',
  'no mention if there (was|were) outliers?',
  '^outliers were not (removed|discussed)',
  '^did not mention',
  '^not mentioned',
  'no, did not mention outliers at all',
  'yes outliers were reported', # reported, but not removed
  'outliers were check(ed)? but none removed',
  'not removed and was justified',
  'not? outliers? (appear to be|were|were seen to be) removed'
)
outliers_no = paste(outliers_no, collapse = '|')
# There were outliers which were removed but they did not have a justification for doing so:
outliers_no_just = c(
  'not? justification as to why',
  'excluded but no clear justification if they were outliers',
  'there was no justification',
  'i would say no',
  'mentioned to be removed',
  'outliers were mentioned but not reported what data',
  'unclear i(s|f) they were removed', # grouped unclear with no
  'removed but there was no justifi',
  'removed with(out| no) justifi'
)
outliers_no_just = paste(outliers_no_just, collapse = '|')
# There were outliers identified which were removed with a justification:
outliers_just = c(
  '(well|with) justifi',
  'short justification provided', # borderline?
  'outliers were removed with and without justification', # added to justified as being generous
  'had justification with reference'
)
outliers_just = paste(outliers_just, collapse = '|')


# q14a, questions answered
questions_yes = c(
  '(research questions?|study aims?|study purposes?)(of (the|this) study )?(was|were) answered',
  'yes (both |each of )?the (purposes?|goals?) of (the|this) (research )?study (was|were) (met|answered)',
  'yes (both |each of )?the (study )?(goals?|aims?|purposes?) (was|were) (met|answered)',
  'yes (both |each of )?the (research aims?|aims?|objectives?) of (the|this) (study|research) (was|were)( largely)? answered',
  'yes (both |each of )?the article answered the research aim',
  'yes (the|all) aims? (of (the )?study )?(was|were) answered',
  '^yes$',
  '^yes, ',
  '^aim was answered$',
  '^both the research aims were answered',
  'yes (both|each) research aims? (was|were) answered',
  'yes the aim and research questions were answered',
  '^the research (questions?|aims?) (was|were) answered',
  '^the purposes? of this (research )?study (was|were) answered',
  '^the aims? of the study (were|was) answered',
  'the goals? of the study (were|was) met',
  'the study answered the research aims?',
  '^yes for both',
  '^seems\\.',
  'yes the aims? of the study and research questions (was|were) answered',
  'yes (both |each of )?the (purposes? and )?aims? of (the|this) study were answered',
  'yes (both |each of )?the (research |study )(purposes?|questions?|aims?) (of (the|this) study )?(was|were) (largely )?(met|answered|well answered)'
)
questions_yes = paste(questions_yes, collapse = '|')
questions_no = c(
  '^no, ',
  '^partially, ',
  '(research questions?|study aims?|study purpose) (was|were) not answered',
  'the purpose of the study changed in the discussion'
)
questions_no = paste(questions_no, collapse = '|')

# Q14b
practical_yes = c(
  '^yes\\b',
  'yes for both aims and hypotheses',
  '^seems\\b', # being generous
  'partially, only reliability was adequately reported', # being generous
  'there (was|were) great reflection and practical significance',
  'there (was|were) (strong )?practical reflection on the results',
  'there (was|were) (some )?practical reflections?',
  'there (was|were) (some )?reflection on the practical significance',
  'reflection on the practical significance was made'
)
practical_yes = paste(practical_yes, collapse = '|')
practical_no = c(
  '^no\\b',
  'no, i did not find their rqs',
  'practical significance was limited',
  '(little and )?no clear reflection (of the results )?on (the )?practical outcomes?',
  'little (practical )?reflections? on (the )?(practical )?outcomes?',
  '(no|limited) (clear )?(significant|practical) reflections? on the (outcomes?|results?)',
  'no clear practical reflections?',
  'little to no practical reflection seen'
)
practical_no = paste(practical_no, collapse = '|')

## for textclean package as current version is changing ratios (used by 5_read_pdf_files_to_xml_automate.R)
# see https://github.com/trinker/textclean/issues/67
textclean_time_pattern = "(2[0-3]|[01]?[0-9]):([0-5][0-9])[.:]?([0-5]?[0-9])?"
