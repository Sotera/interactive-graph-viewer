#server.R

library(DT)
library(shiny)
library(igraph)
library(ggplot2)

initial_data <- "./www/data/ctd.csv"
graph <- NULL
communities <- NULL

function(input, output, session){ 
  
  source("external/graph_utils.R", local = TRUE)
  source("external/makenetjson.R", local = TRUE)
  
  global_state <- reactiveValues(community = NULL, 
                                 current_graph_type = NULL)
  
  # reset button
  observeEvent(input$reset_button, {
    global_state$community = NULL
  })
  
  # on-click from sigma.js
  observeEvent(input$comm_id, {
    if (global_state$current_graph_type == "community"){
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
      graph <<- subgraph_of_one_community(graph, communities, id)      
    }
    
    # if the graph we are looking at has more than 200 points 
    # run community detection to make it easier to visualize
    if (vcount(graph) > 500){
      communities <<- get_communities(graph)
      community_graph <- get_community_graph(graph, communities)
      global_state$current_graph_type = "community"
      makenetjson(community_graph, "./www/data/current_graph.json", comm_graph = TRUE) 
      update_stats(community_graph, global_state$current_graph_type)
    } else {
      V(graph)$size <- 1
      global_state$current_graph_type = "not_community"
      makenetjson(graph, "./www/data/current_graph.json", comm_graph = FALSE)
      update_stats(graph, global_state$current_graph_type)
    }
    
    return(includeHTML("./www/graph.html"))
  })
  
  
  update_stats <- function(graph, state){
    nodes <- get.data.frame(graph, what="vertices")
    nodes$degree <- degree(graph)
    nodes$pagerank <- page_rank(graph)$vector
    if (state == 'community'){
      colnames(nodes) <- c("Name", "Type", "Comm", "Size", "Degree", "PageRank")
    } else {
      colnames(nodes) <- c("Name", "Type", "Comm", "Degree", "PageRank")
    }
    global_state$nodes <- nodes
  }
  
  # Plot the degree distribution of the current graph
  output$degree_distribution <- renderPlot({  
    if (!is.null(global_state$nodes)){
      ggplot(global_state$nodes, aes(x=Degree)) + geom_histogram(alpha=.3)
    }
  })
  
  # Plot the pagerank distribution of the current graph
  output$pagerank_distribution <- renderPlot({
    if (!is.null(global_state$nodes)){
      ggplot(global_state$nodes, aes(x=PageRank)) + geom_histogram(alpha=.3)
    }    
  })
  
  # Generate a table of node degrees
  output$degree_table <- DT::renderDataTable({
    if (!is.null(global_state$nodes)){
      table <- global_state$nodes[c("Name", "Degree", "PageRank")]
      }
    },
    options = list(order = list(list(1, 'desc'))),
    rownames = FALSE
  )
  
  
  newf <-function(){
    print("stuff")
  }




}
