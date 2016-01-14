library(jsonlite)

makenetjson<-function(gcomm, filename, comm_graph){
  gcomm=simplify(gcomm, edge.attr.comb=list("sum"), remove.loops=FALSE)
  
  # We need the following attributes for sigma
  #  - id
  #  - label
  #  - size 
  #  - x 
  #  - y
  # - type (I'll base the color of the node off of type in the javascript)
  
  gcommlayout=layout_with_kk(gcomm, kkconst = vcount(gcomm)/2);
  V(gcomm)$x=gcommlayout[,1]
  V(gcomm)$y=gcommlayout[,2]
  
  nodedf=get.data.frame(gcomm, what="vertices")
  nodedf$id = nodedf$name
  if (comm_graph){
    nodedf$label = as.character(nodedf$comm)
    nodedf$type = rep("Community", times = vcount(gcomm))
  } else {
    nodedf$label= nodedf$name
  }
  
  edgedf=get.data.frame(gcomm, what="edges");
  edgeids=vector("character", ecount(gcomm))
  if (ecount(gcomm)>0){
    for(i in 1:ecount(gcomm)){edgeids[i]=paste0("e", as.character(i))}
    edgedf2=data.frame(source=as.character(edgedf$from), target=as.character(edgedf$to), id=edgeids)
  } else {
    edgedf2=data.frame(source=character(), target=character())
  }
  edges_json=paste0("\"edges\":", jsonlite::toJSON(edgedf2))
  nodes_json=paste0("\"nodes\":", jsonlite::toJSON(nodedf))
  all_json=paste0("{", nodes_json, ",", edges_json, "}")
  sink(file=filename)
  cat(all_json)
  sink()
}