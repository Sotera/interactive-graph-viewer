
build_initial_graph <-function (file){
  # Uses igraph to parse the initial, full graph
  table <- read.csv(file, header = TRUE, sep = ",")
  edges <- table[c('entity1', 'entity2')]
  data1 <- table[c('entity1', 'type1')]
  data2 <- table[c('entity2', 'type2')]
  colnames(data1) <- c('entity', 'type')
  colnames(data2) <- c('entity', 'type')
  vertex_data <- unique(rbind(data1, data2))
  g <- graph_from_data_frame(edges, directed = FALSE, vertices = vertex_data)
  return(g)
}


graph_to_sigma_json <-function (graph){
  # converts an igraph graph into json that sigma will understand
  # igraph writes the graph out as xml and I use a python utility 
  # to convert it into a json 
  write.graph(graph = graph, 
              file = "./www/data/tmp.xml",
              format = "graphml")
  cmd <- "/usr/local/bin/python xml_to_json.py"
  system(cmd)
}


get_communities <- function(graph){
  # Runs louvain community detection
  return(multilevel.community(graph))
}