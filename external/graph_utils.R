library(plyr)
library(igraph)
library(MASS)

source("external/protein_label_dictionary.R",local = TRUE)



build_initial_graph <-function (conf){
  # Uses igraph to parse the initial, full graph
  vert_atr<-TRUE
  file <- conf$FilePath
  ent1<-conf$Entity1_Col
  typ1<-conf$Type1_Col
  ent2 <- conf$Entity2_Col
  typ2 <- conf$Type2_Col
  typ_colors <- conf$Type_colors
  
  
  #print(typ1_types)
  #print(typ2_types)
  # if(is.null(conf$Type1_Col))
  # {
  #   vert_atr<-FALSE
  #   typ1<- "type1"
  #   typ2<-"type2"
  #   table[,typ1] <- "Entity1"
  #   table[,typ2] <- "Entity2"
  # }
  
  
  table <- read.csv(file, header = TRUE, sep = ",",stringsAsFactors = F)
  
 

  #print(typ1)
  lookup <- typ_colors[[1]]
  
  edges <- table[c(ent1, ent2)]
  data1 <- table[c(ent1, typ1)]
  
  
  for(ii in lookup$Entity){
    indxdata1 <- which(data1[,typ1]==ii)
    data1[indxdata1,"color"] <- lookup[which(lookup$Entity== ii),]$Color
  }
  
  #lookup <- typ2_types[[1]]
  
  data2 <- table[c(ent2, typ2)]
  for(ii in lookup$Entity){
    indxdata2 <- which(data2[,typ2]==ii)
    data2[indxdata2,"color"] <- lookup[which(lookup$Entity== ii),]$Color
    
  }
  
  
   
  colnames(data1) <- c('entity', 'type','color')
  colnames(data2) <- c('entity', 'type','color')
  vertex_data <- unique(rbind(data1, data2))
  #print(vertex_data)
  if(vert_atr==TRUE){
    g <- graph_from_data_frame(edges, directed = FALSE, vertices = vertex_data)
    #g1<-set.vertex.attribute(g, "entity", index=V(g), "entity1")
    return(g)
  }
  else
  {
    g <- graph_from_data_frame(edges, directed = FALSE)
    g1<-set.vertex.attribute(g, "entity", index=V(g), "entity1")
    return(g1)
  }
  
}


get_communities <- function(graph,alg="lv"){
  # Runs louvain community detection
  if(alg=="lv"){
  return(cluster_louvain(graph))
  }
  else if(alg=="wk"){
    return(cluster_walktrap(graph))
  }
  else if(alg=="fg"){
    return(cluster_fast_greedy(graph))
  }
  else if(alg=="imap"){
    return(cluster_infomap(graph))
  }
  else if(alg=="ebetweens"){
    return(cluster_edge_betweenness(graph))
  }
  else if(alg=="lp"){
    return(cluster_label_prop(graph))
  }
  else if(alg=="sg"){
    return(cluster_spinglass(graph))
  }
}

get_community_graph <- function(graph, communities){
  # Builds a graph of the communities
  #print(length(communities$membership))
  V(graph)$comm <-communities$membership
  contracted <- contract.vertices(graph, communities$membership, "random")
  community_graph <- simplify(contracted, "random")
  V(community_graph)$name <- V(community_graph)$comm
  
  # Set the size of each node to be proportional to the community size
  counts <- count(communities$membership)
  V(community_graph)$size <- counts$freq
  V(community_graph)$type <- "Community"
  
  #labellist <- lapply(communities(communities),len)
  #rawlabels <- lapply(labellist,unlist)
  #labelfreq <- lapply(rawlabels,table)
  #piechrts <- lapply(labelfreq,getpie)
  #print(piechrts)
  #maxlabel <- lapply(labelfreq,getmax)
  
  #V(community_graph)$labelfreq <- labelfreq
  #V(community_graph)$LabelInfo <- maxlabel
  return(community_graph)
}

subgraph_of_one_community <- function(graph, communities, community_id){
  # Builds a subgraph of one community from the original graph
  idx <- which(communities$membership == community_id)
  subgraph <- induced.subgraph(graph, idx)
  return(subgraph)
}