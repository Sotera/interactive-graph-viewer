library(DT)
library(shiny)
library(igraph)
library(plotly)
library(rstackdeque)

source("external/graph_utils.R", local = TRUE)
source("external/makenetjson.R", local = TRUE)

initial_data <- "./www/data/ctd.csv"
graph <- build_initial_graph(initial_data)
communities <- get_communities(graph)
htmlloaded = FALSE
s1 <- rstack()
s2 <-rstack()

function(input, output, session){ 
  global <- reactiveValues()
  global$is_comm_graph = TRUE
  global$viz_stack <- insert_top(s1, list(graph, communities))
  global$name <- insert_top(s2, "")
  
  
  # reset button
  observeEvent(input$reset_button, {
    graph <- build_initial_graph(initial_data)
    communities <- get_communities(graph)
    global$viz_stack <- rstack()
    global$viz_stack <- insert_top(global$viz_stack, list(graph, communities))
    global$name <- insert_top(s2, "")
  })
  
  
  #Search button
  observeEvent(input$search_button,{
    searchelm <- input$searchentitiy
    data <- peek_top(global$viz_stack)
    graph <- data[[1]]
    communities <- data[[2]]
    if (global$is_comm_graph){
      memcommunity <- communities$membership[which(searchelm== V(graph)$name)]
    } else {
      memcommunity <- searchelm
      print(memcommunity)
    }
    observe({
      session$sendCustomMessage(type = "commmemmsg" ,
                                message = list(id=memcommunity))
    })
  })
  
  # table click
  observe({
    row <- input$degree_table_rows_selected
    if (length(row)){
      print(row)
      session$sendCustomMessage(type = "commmemmsg" ,
                                message = list(id=tail(row, n=1)))
    }
  })
  
  
  # back button
  observeEvent(input$back_button, {
    size <- length(global$viz_stack)
    if (size > 1){
      global$viz_stack <- without_top(global$viz_stack)
      global$name <- without_top(global$name)
    } 
  })
  
  # on-click from sigma.js
  observeEvent(input$comm_id, {
    if (global$is_comm_graph){
      data <- peek_top(global$viz_stack)
      graph <- data[[1]]
      communities <- data[[2]]
      graph <- subgraph_of_one_community(graph, communities, input$comm_id) 
      communities <- get_communities(graph)
      global$viz_stack <- insert_top(global$viz_stack, list(graph, communities))
      global$name <- insert_top(global$name, input$comm_id)      
    }
  })
  
  # writes out the current viz graph to a json for sigma
  graph_to_write <- reactive({
    data <- peek_top(global$viz_stack)    
    graph <- data[[1]]
    communities <- data[[2]]
    
    # Try and apply community detection if there are a lot of nodes to visualize
    if (vcount(graph) > 500){
      community_graph <- get_community_graph(graph, communities)
      if (vcount(community_graph) > 1){ 
        global$is_comm_graph <- TRUE
        return(list(community_graph, TRUE))
      }
    } 
    
    # If we have few enough nodes (or would have just 1 (sub)community) visualize as is
    V(graph)$size <- 1
    global$is_comm_graph <- FALSE
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
  })
  
  # render with sigma the current graph (in json)
  output$graph_with_sigma <- renderUI({
    data <- graph_to_write()
    makenetjson(data[[1]], "./www/data/current_graph.json", data[[2]]) 
    update_stats(data[[1]], data[[2]])
    
    observe({
      session$sendCustomMessage(type = "updategraph",message="xyz")
    })
    
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
    global$nodes <- nodes
  }
  
  # Plot the degree distribution of the current graph
  output$degree_distribution <- renderPlotly({  
    if (!is.null(global$nodes)){
      plot_ly(global$nodes, x = Degree, type="histogram",  color="#FF8800")
    }
  })
  
  # Plot the pagerank distribution of the current graph
  output$pagerank_distribution <- renderPlotly({
    if (!is.null(global$nodes)){
      plot_ly(global$nodes, x = PageRank, type="histogram", color="#FF8800")
    }    
  })
  
  # Generate a table of node degrees
  output$degree_table <- DT::renderDataTable({
    if (!is.null(global$nodes)){
      table <- global$nodes[c("Name", "Degree", "PageRank")]
    }
  },
  options = list(order = list(list(1, 'desc'))),
  rownames = FALSE,
  selection = "single"
  )
  
  # Generate the current graph name (as a list of community labels)
  output$name <- renderText({
    name <- as.list(rev(global$name))
    name <- paste(name, collapse = "/", sep="/")
    return(paste(c("Current Community", name)))
  })
  
}
