#server.R

library(shiny)
library(igraph)

initial_data <- "./www/data/ctd.csv"
graph <- NULL
communities <- NULL

function(input, output, session){ 
  
  source("external/graph_utils.R", local = TRUE)
  source("external/makenetjson.R", local = TRUE)

  
  # reset button
  observeEvent(input$reset_button, {
    updateNumericInput(session, "comm_id", value = -1)
    graph <<- NULL
    communities <<- NULL
  })
  
  # Regenerate the current graph visualization
  output$graph_with_sigma <- renderUI({
    
    # Get the community id
    id <- input$comm_id 
    
    # If we don't already have a graph build one
    if (is.null(graph)){
      graph <<- build_initial_graph(initial_data)
    }
    
    # If we selected a community zoom into just that community
    if (!is.null(id) && id >0){
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
