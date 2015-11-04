#server.R

library(shiny)
library(igraph)

initial_data <- "./www/data/ctd.csv"
graph <- NULL
communities <- NULL

function(input, output, session){ 
  
  source("external/graph_utils.R", local = TRUE)
  source("external/makenetjson.R", local = TRUE)

  global_state <- reactiveValues(community = NULL, current_graph_type = NULL)
  
  # reset button
  observeEvent(input$reset_button, {
    global_state$community = NULL
  })
  
  # on-click from sigma.js
  observeEvent(input$comm_id, {
    if (v$current_graph_type == "community"){
      global_state$community = input$comm_id
    }
  })
  
  # Regenerate the current graph visualization
  output$graph_with_sigma <- renderUI({
    # Get the community id
    id <- global_state$community

    # If we don't have a community then build the first graph,
    # otherwise select the desired community subgraph
    if (is.null(id)){
      graph <<- build_initial_graph(initial_data)
    } else {
      graph <<- community_subgraph(graph, communities, id)      
    }
    
    # if the graph we are looking at has more than 200 points 
    # run community detection to make it easier to visualize
    if (vcount(graph) > 500){
      communities <<- get_communities(graph)
      V(graph)$comm <-communities$membership
      contracted <- contract.vertices(graph, communities$membership, "random")
      community_graph <- simplify(contracted, "random")
      V(community_graph)$name <- V(community_graph)$comm
      V(community_graph)$size <- 1
      
      
      global_state$current_graph_type = "community"
      makenetjson(community_graph, "./www/data/current_graph.json", comm_graph = TRUE)  
    } else {
      graph$size <- 1
      global_state$current_graph_type = "not_community"
      makenetjson(graph, "./www/data/current_graph.json", comm_graph = FALSE)   
    }
    
    return(includeHTML("./www/graph.html"))
  })
  
}
