#server.R

library(shiny)
library(igraph)

function(input, output, session){ 

  source("external/graph_utils.R", local = TRUE)
  source("external/makenetjson.R", local = TRUE)
  
  # Regenerate the current graph visualization
  output$graph_with_sigma <- renderUI({
    if (is.null(graph)){
      graph <- build_initial_graph(initial_data)
    }
    communities <- get_communities(graph)
    contracted <- contract.vertices(graph, communities$membership, "random")
    community_graph <- simplify(contracted, "random")
    V(community_graph)$type <- rep('Community', times =length(V(community_graph)))
    #V(community_graph)$name <- 
    
    print(summary(community_graph))
    #graph_to_sigma_json(community_graph)
    makenetjson(community_graph, "./www/data/current_graph.json")
    return(includeHTML("./www/graph.html"))
  })

}
