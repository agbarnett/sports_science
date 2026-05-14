# 8_author_network.R
# called by 8_articles_report.Rmd
# see https://r-graph-gallery.com/251-network-with-node-size-based-on-edges-number.html
# Feb 2025
library(igraph)

# create data of author network
links = NULL
for (d in unique(author_frame$doi)){
  this_paper = filter(author_frame, doi == d)
  if(nrow(this_paper)==1){next} # no network with single author
  combs = combn(1:nrow(this_paper), 2)
  for (j in 1:ncol(combs)){
     f = data.frame(source = this_paper$display_name[combs[1,j]],
                    target = this_paper$display_name[combs[2,j]])
     links = bind_rows(links, f)
  }
}

# only authors with this many mentions 
tab = table(c(links$source, links$target))
over = tab[tab >= min_mentions]
names = names(over)
links = filter(links, source %in% names,
               target %in% names)

# character returns for names
links = mutate(links, 
               source = str_replace(source, ' [A-Z]\\.\\b','\n'), # drop middle initial
               source = str_replace(source, ' ','\n'),
               target = str_replace(target, ' [A-Z]\\.\\b','\n'),
               target = str_replace(target, ' ','\n'))

# Turn it into igraph object
network <- graph_from_data_frame(d = links, directed = FALSE) 

# Count the number of degree for each node:
deg <- degree(network, mode="all")


# Plot
par(mai = rep(0,4)) # reduce margins
plot(network, 
     vertex.size = deg*1, 
     vertex.frame.color = NA, # no colours around nodes
     edge.color = 'grey88', # joining lines
     vertex.label.color = 'black', # text colour
     vertex.color = 'pink' ) # node color

