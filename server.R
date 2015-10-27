#server.R

library(shiny)
library(igraph)

initial_data <- "./www/data/ctd.csv"
graph <- NULL
communities <- NULL

function(input, output, session){ 
  
  source("external/graph_utils.R", local = TRUE)
  source("external/makenetjson.R", local = TRUE)

  v <- reactiveValues(community = NULL)
  
  # reset button
  observeEvent(input$reset_button, {
    v$community = NULL
    print(v$community)
  })
  
  # on-click from sigma.js
  observeEvent(input$comm_id, {
    v$community = input$comm_id
    print(v$community)
  })
  
  # Regenerate the current graph visualization
  output$graph_with_sigma <- renderUI({
    print("-----------")
    # Get the community id
    id <- v$community
    print(id)
    
    # If we don't have a community then build the first graph,
    # otherwise select the desired community subgraph
    if (is.null(id)){
      graph <<- build_initial_graph(initial_data)
    } else {
      print("Trying to subgraph")
      graph <<- community_subgraph(graph, communities, id)      
    }
    
    # if the graph we are looking at has more than 200 points 
    # run community detection to make it easier to visualize
    if (vcount(graph) > 200){
      communities <<- get_communities(graph)
      V(graph)$comm <-communities$membership
      contracted <- contract.vertices(graph, communities$membership, "random")
      community_graph <- simplify(contracted, "random")
      makenetjson(community_graph, "./www/data/current_graph.json", comm_graph = TRUE)      
    } else {
      print("Got here?")
      makenetjson(graph, "./www/data/current_graph.json", comm_graph = FALSE)   
    }
    
    return(includeHTML("./www/graph.html"))
  })
  
}
