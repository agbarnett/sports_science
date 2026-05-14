# 7_model_statistician.R
# can we predict what authors are a statistician or not using the BMJ data?
# none of the models are very good, so did not use
# May 2026
library(glmnet)
library(rpart) # for tree
library(e1071) # for support vector machine

# get the data from 6_statisticians_bmj_data.R
load('data/6_bmj_roles.RData')
# prepare data into a matrix and vector
x = as.matrix(select(wide, -name, -statistician))
logx = sqrt(x + 1) # because of enormous skew in some answers
y = as.numeric(wide$statistician == TRUE)

## simple table of key column
with(wide, table(statistician, `Statistics and Probability` > 0))

## run classification tree
my.control = rpart.control()
my.control$cp = 0.0001
tree = rpart(formula = y ~ x)
rsq.rpart(tree)


## run lasso, small alpha much better
m1 = glmnet(x = logx, y = y, family = 'binomial', alpha = 0)
cv1 = cv.glmnet(x = logx, y = y, family = 'binomial', alpha = 0)
plot(cv1)
coef(cv1, s = "lambda.1se")

# predictions from lasso
preds = predict(m1, newx = x, type = "response", s = cv1$lambda.1se)
pframe = select(wide, name, statistician) %>%
  bind_cols(preds)
names(pframe)[3] = 'pred'
pframe = mutate(pframe, pred = round(pred * 1000) / 1000) # round for ease of comparison
with(pframe, table(statistician, pred > 0.999))

# summarise
stats = group_by(pframe, statistician) %>%
  summarise(n = n(), mean = mean(pred), sd = sd(pred))
pvars = bind_rows(pvars, stats)

## support vector machine
sres = svm(y = y, x = logx)
#print(sres)
#summary(sres)
# predictions from SVM
preds = predict(sres)
pframe = select(wide, name, statistician) %>%
  bind_cols(preds)
names(pframe)[3] = 'pred'
pframe = mutate(pframe, pred = round(pred * 1000) / 1000) # round for ease of comparison
with(pframe, table(statistician, pred > 0.029))

# none of the predictions are very good
# not sure that OpenAlex is the ideal data set; some measurement error
