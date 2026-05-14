# 99_data_collection_summary.R
# summary of data collection
# March 2025
library(dplyr)
library(ggplot2)
library(readxl)
library(tidyr)

# get the data
data = read_xlsx(path = 'data/99_data_collection.xlsx') %>%
  mutate(x = 1:n(),
         q = paste(Question, ', ', Label, sep=''),
         q = ifelse(Question == 'q99', Label, q)) # alternative label for one
# wide to long
to_plot = select(data, x, q, RA, Automated, AIS) %>% 
  rename('1' = 'RA',
         '2' = 'Automated',
         '3' = 'AIS') %>% # for ordering
  pivot_longer(c(-x, -q))

# labels
n = nrow(data)
xlabels = data$q

# plot
colours = c("firebrick2", "aquamarine3", "goldenrod1")
tplot = ggplot(to_plot, aes(x, name, width = 1)) +
  geom_tile(aes(fill = factor(value)), colour = "grey44")+
  scale_fill_manual(NULL, values=colours,na.value = 'grey88')+
  xlab('')+
  ylab('')+
  scale_x_reverse(breaks = 1:n, labels = xlabels, expand = c(0,0))+ # earliest questions at top
  scale_y_discrete(breaks = c('1','2','3'), 
                   labels = c('Research\nassistant','Automated','AIS'),
                   expand=c(0,0))+
  coord_flip()+
  theme(legend.position = 'none')
tplot

# export
ggsave('figures/99_data_collection_tile.jpg', plot = tplot, width = 4.5, height=6, units = 'in', dpi=500)
