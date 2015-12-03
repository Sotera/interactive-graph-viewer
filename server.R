library(DT)
library(shiny)
library(igraph)
library(ggplot2)
library(rstackdeque)

source("external/graph_utils.R", local = TRUE)
source("external/makenetjson.R", local = TRUE)

initial_data <- "./www/data/ctd.csv"
graph <- build_initial_graph(initial_data)
communities <- get_communities(graph)
s <- rstack()

function(input, output, session){ 
  global_state <- reactiveValues()
  global_state$community = NULL
  global_state$is_comm_graph = TRUE
  global_state$viz_stack <- insert_top(s, list(graph, communities, TRUE))
  
  # reset button
  observeEvent(input$reset_button, {
    global_state$community = NULL
    graph <- build_initial_graph(initial_data)
    communities <- get_communities(graph)
    global_state$viz_stack <- rstack()
    global_state$viz_stack <- insert_top(global_state$viz_stack, list(graph, communities, TRUE))
  })
  
  # back button
  observeEvent(input$back_button, {
    size <- length(global_state$viz_stack)
    if (size > 1){
      global_state$viz_stack <- without_top(global_state$viz_stack)
    } else {
      global_state$viz_stack <- global_state$viz_stack
    }  
  })
  
  
  # filter radio buttons
  observeEvent(input$interactions, {
    global_state$community = NULL
  })
  
  # on-click from sigma.js
  observeEvent(input$comm_id, {
    if (global_state$is_comm_graph){
      global_state$community = input$comm_id
      data <- peek_top(global_state$viz_stack)
      graph <- data[[1]]
      communities <- data[[2]]
      graph <- subgraph_of_one_community(graph, communities, global_state$community) 
      communities <- get_communities(graph)
      global_state$viz_stack <- insert_top(global_state$viz_stack, list(graph, communities, TRUE))
    }
  })
  
  # writes out the current viz graph to a json for sigma
  graph_to_write <- reactive({
    data <- peek_top(global_state$viz_stack)    
    graph <- data[[1]]
    communities <- data[[2]]
    
    if (vcount(graph) > 500){
      community_graph <- get_community_graph(graph, communities)
      global_state$is_comm_graph <- TRUE
      return(list(community_graph, TRUE))
    } else {
      V(graph)$size <- 1
      global_state$is_comm_graph <- FALSE
      if(input$interactions!= "all"){
        dellist <- c()
        indx <-1
        for(nd in V(graph)){
          atr <- get.vertex.attribute(graph,"type",nd)
          if(grepl(atr,input$interactions) == FALSE){
            dellist[indx] <- nd
            indx <- indx+1
          }
          
        }
        graph <- delete.vertices(graph,dellist)
      }
      return(list(graph, FALSE))
    }
  })
  
  # render with sigma the current graph (in json)
  output$graph_with_sigma <- renderUI({
    data <- graph_to_write()
    makenetjson(data[[1]], "./www/data/current_graph.json", data[[2]]) 
    update_stats(data[[1]], data[[2]])
    return(includeHTML("./www/graph.html"))
  })
  
  # update the summary stats
  update_stats <- function(graph, is_comm_graph){
    nodes <- get.data.frame(graph, what="vertices")
    nodes$degree <- degree(graph)
    nodes$pagerank <- page_rank(graph)$vector
    if (is_comm_graph==TRUE){
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

}
