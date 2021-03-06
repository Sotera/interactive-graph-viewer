library(DT)
library(shiny)
library(igraph)
library(plotly)
library(rstackdeque)
library(jsonlite)
options(shiny.maxRequestSize = 100*1024^2) #100MB file size limit 
source("external/graph_utils.R", local = TRUE)
source("external/makenetjson.R", local = TRUE)
source("external/protein_label_dictionary.R",local = TRUE)


conf <- fromJSON("./www/data/config.json")
#check if rds file already exists
graph_file_rds=paste(conf$FilePath,"_graph.rds",sep="")
comm_file_rds=paste(conf$FilePath,"_communities.rds",sep="")
if(!file.exists(graph_file_rds)){
  
  graph <- build_initial_graph(conf)
}else{
  print("Loading graph from rds ")
  graph<-readRDS(graph_file_rds)
}


if(!file.exists(comm_file_rds)){
  communities <- get_communities(graph)
}else{
  print("Loading communities from rds ")
  communities<-readRDS(comm_file_rds)
}
print(conf$FilePath)
saveRDS(graph,paste(conf$FilePath,"_graph.rds",sep=""))
saveRDS(communities,paste(conf$FilePath,"_communities.rds",sep=""))
htmlloaded = FALSE
s1 <- rstack()
s2 <-rstack()
s3 <- rstack()
mp <<- NULL
sortedlabel<-NULL
protienDSpathway<<-data.frame()
disptable<<-NULL
lbllist<<-NULL
is_comm_graph <- TRUE
colormapping<-data.frame(Entity=character(),Color=character(),stringsAsFactors = FALSE)
interactionmapping<-data.frame(Entity1=character(),Entity2=character(),stringsAsFactors = FALSE)
# uniqueentities <<- NULL


function(input, output, session){ 
  global <- reactiveValues()
  global$viz_stack <- insert_top(s1, list(graph, communities))
  global$name <- insert_top(s2, "")
  
  typ_colors <- conf$Type_colors
  tcDF <- typ_colors[[1]]
  
  # render with sigma the current graph (in json)
  output$graph_with_sigma <- renderUI({
    print("output$graph_with_sigma")
    data <- graph_to_write()
    makenetjson(data[[1]], "./www/data/current_graph.json", data[[2]],conf) 
    update_stats(data[[1]], data[[2]])
    
    observe({
      session$sendCustomMessage(type = "updategraph",message="xyz")
    })
    
    return(includeHTML("./www/graph.html"))
  })
  
  # Generate the current graph name (as a list of community labels)
  output$name <- renderText({
    name <- as.list(rev(global$name))
    name <- paste(name, collapse = "/", sep="/")
    return(paste(c("Current Community", name)))
  })
  
  # Generate a table of node degrees
  output$entities_table <- DT::renderDataTable({
    if (!is.null(global$nodes)){
      # table <- global$nodes[c("Name", "Type", "Degree","PageRank")]
      table <- global$nodes[c("name", "type", "degree","pagerank")]
    }
  },
  options = list(order = list(list(1, 'desc'))),
  rownames = FALSE,
  selection = "single"
  )
  
  # Plot the degree distribution of the current graph
  output$degree_distribution <- renderPlotly({  
    if (!is.null(global$nodes)){
      x <-list(
        title = "Degree"
      )
      y <- list(
        title = "Number of nodes"
      )
      plot_ly(x = global$nodes[["degree"]], type="histogram",  color="#FF8800") %>%
        layout(xaxis = x, yaxis = y)
    }
  })
  
  # Plot the pagerank distribution of the current graph
  output$pagerank_distribution <- renderPlotly({
    if (!is.null(global$nodes)) {
      x <-list(
        title = "PageRank"
      )
      y <- list(
        title = "Number of nodes"
      )
      plot_ly(x = global$nodes[["pagerank"]], type="histogram",  color="#FF8800") %>%
        layout(xaxis = x, yaxis = y)
    }    
  })
  
  output$plotgraph1 <-DT::renderDataTable(
    {
      print("output$plotgraph1")
      protienDSpathway<<-data.frame()
      sortedlabel<-NULL
      #labelfreq <- lapply(rawlabels,table)
      proteins<-global$nodes[global$nodes$type=="Protein","name"]
      print("Printing Proteins ..")
      #print(proteins)
      
      # This takes forever. If we can load a previously built object do it; otherwise don't hold your breath
      withProgress(message = "Loading ...",value = 0,{
        if(is.null(mp)){
          filename = 'mp.rds'
          if (file.exists(filename)){
            mp <<- NULL
            mp <<- readRDS(filename)
          } else {
            mp <<- getproteinlabeldict()
            saveRDS(mp, file=filename)
          }
        }
      })
      lapply(proteins,appendlabel)
      
      table <- data.frame(Protein="No pathway data available")
      
      if (nrow(protienDSpathway)>1){
        labelfreq <- table(protienDSpathway)
        if (ncol(labelfreq)>1){
          z<-apply(labelfreq,1,sum)
          sortedlabel<-labelfreq[order(as.numeric(z), decreasing=TRUE),]
          disptable<<-as.data.frame.matrix(sortedlabel)
        } else {
          disptable <<- as.data.frame.matrix(labelfreq)
        }
        row.names(disptable) <<- strtrim(row.names(disptable), 50)
      } 
      disptable
    },
    rownames = TRUE,
    selection = "single"
  )
  
  output$choose_entTypes <- renderUI({
    dat <- read.csv(conf$FilePath, header = input$header,
                    sep = input$sep, quote = input$quote)
    x<-paste(dat[,"type1"],dat[,"type2"],collapse = ",",sep=",")
    uniqueentities<<-unique(unlist(strsplit(x,",")))
    
    uniqueentities <- unlist(tcDF[[1]])
    
    # Create the checkboxes and select them all by default
    checkboxGroupInput("entTypes", "Entity Types",
                       choices  = uniqueentities,
                       selected = uniqueentities)
  })
  
  # output$legend <- renderTable(tcDF)
  
  
  trList = list()
  for (i in seq_len(nrow(tcDF))) {
    trList[[i]] <- tags$tr(
      tags$td(span(style = sprintf(
       "width:1.1em; height:1.1em; background-color:%s; display:inline-block;",
       tcDF[i,2]
      ))),
      tags$td(tcDF[i,1])
    )
  }
  
  output$legend <- renderUI({
    tags$table(class = "table",
      tags$thead(tags$tr(
       tags$th("Color"),
       tags$th("Entity")
      )),
      tags$tbody(
       trList,
       tags$tr(
         tags$td(span(style = sprintf(
           "width:1.1em; height:1.1em; background-color:%s; display:inline-block;",
           conf$community_color
         ))),
         tags$td("Community")
       )
      )
    )
  })

  # Populate Entity definitions dropdowns if input file is selected
  output$contents <- renderTable({
    print("output$contents")
    inFile <- input$file1
    
    if (is.null(inFile))
      return(NULL)
    
    dat <- read.csv(inFile$datapath, header = input$header,
                    sep = input$sep, quote = input$quote)
    
    updateSelectInput(session,"entity1",choices = colnames(dat))
    updateSelectInput(session,"entity2",choices = colnames(dat))
    updateSelectInput(session,"type1",choices = colnames(dat))
    updateSelectInput(session,"type2",choices = colnames(dat))
    return (NULL)
  })

  output$plotgraph2 <- renderPlotly({ 
    #withProgress(message = "Loading ...",value = 0,{
    #getrawentititesfromComm(global$currentCommId)
    #})
    labelfreq <- table(protienDSpathway)
    z<-apply(labelfreq,1,sum)
    sortedlabel<-labelfreq[order(z, decreasing=TRUE),]
    x<-as.data.frame(sortedlabel,row.names=rownames(sortedlabel),col.names=colnames(sortedlabel))
    
    
    plot_ly(z = sortedlabel,x=colnames(sortedlabel),y=rownames(sortedlabel), type = "heatmap",hoverinfo = "text",
            text = paste(colnames(sortedlabel),rownames(sortedlabel)),colorscale = "Hot") %>% layout(xaxis = list(title="Proteins"),yaxis=list(title="Disease Pathway"))
  })
  
  # Event handler for Done button in Entity definitions tab
  # Update dropdowns in Define Entity interactions and Entity colors
  observeEvent(input$entitymapping_button, {
    inFile <- input$file1
    dat <- read.csv(inFile$datapath, header = input$header,
                    sep = input$sep, quote = input$quote)
    x<-paste(dat[,"type1"],dat[,"type2"],collapse = ",",sep=",")
    uniqueentities<<-unique(unlist(strsplit(x,",")))
    updateSelectInput(session,"entcolors",choices = uniqueentities)
    updateSelectInput(session,"entintr1",choices=uniqueentities)
    updateSelectInput(session,"entintr2",choices=uniqueentities)
    # updateCheckboxGroupInput(session,"entTypes",choices = uniqueentities)
  })
  
  
  # Event handler for Assign color button in Entity colors tab
  # Renders color mappings table when button is pressed
  observeEvent(input$entdone,{
    print(uniqueentities)
    colormapping <<- rbind(colormapping,data.frame(Entity=toString(input[["entcolors"]]),Color=toString(input[["entcol"]])))
    output$enttable <- renderTable(colormapping)
  })
  
  
  # Event handler for Assign interaction button in Define Entity interactions tab
  observeEvent(input$entintrdone,{
    if(nrow(interactionmapping) >0){
      comb1 <- sum(grepl(input[["entintr1"]],interactionmapping$Entity1))
      comb2 <- sum(grepl(input[["entintr2"]],interactionmapping$Entity2))
      comb3 <-sum(grepl(input[["entintr1"]],interactionmapping$Entity2))
      comb4<-sum(grepl(input[["entintr2"]],interactionmapping$Entity1))
      
      if((comb1>0)&&(comb2>0))
        return(NULL)
      if((comb3>0)&&(comb4>0))
        return(NULL)
    }
    interactionmapping <<- rbind(interactionmapping,data.frame(Entity1=toString(input[["entintr1"]]),Entity2=toString(input[["entintr2"]])))
    output$entintrtable <- renderTable(interactionmapping)
  })
  
  
  #saveoptionscsv event
  observeEvent(input$saveoptionscsv,{
    fpath<-input$file1$datapath
    
    for(ent in uniqueentities){
      print(ent)
      if(nrow(colormapping[colormapping$Entity==ent,]) == 0){
        colormapping <<- rbind(colormapping,data.frame(Entity=ent,Color=rgb(runif(1),runif(1),runif(1))))
      }
    }
    
    
    typecolors<-toJSON(colormapping)
    interactions <- toJSON(interactionmapping)
    elements_list = sprintf('[{"FilePath":"%s", 
                            "Entity1_Col": "%s", 
                            "Entity2_Col":"%s",
                            "Type1_Col":"%s",
                            "Type2_Col":"%s",
                            "Type_colors":%s,
                            "Interactions":%s,
                            "community_color":"%s",
                            "community_threshold":"%s"
  }]', fpath, input$entity1,input$entity2, input$type1,input$type2, typecolors,interactions, input$community_col,input$comm_size)
    
    print(elements_list)
    con <- file("./www/data/config_1.json")
    writeLines(elements_list,con)
    close(con)
    conf <<- fromJSON("./www/data/config_1.json")
    resetgraph(conf)
    
  })
  
  
  # reset button
  observeEvent(input$reset_button, {
    resetgraph(conf)
  })
  
  #Search button
  observeEvent(input$search_button,{
    searchelm <- strsplit(input$searchentitiy,",")
    data <- peek_top(global$viz_stack)
    graph <- data[[1]]
    communities <- data[[2]]
    memcomm <- NULL
    if (is_comm_graph){
      ii<-1
      for(elm in unlist(searchelm)){
        print(elm)
        memcomm[ii] <-  communities$membership[which(elm== V(graph)$name)]
        ii<-ii+1
      }
      memcommunity<-paste(memcomm,collapse = ",")
    } else {
      memcommunity <- input$searchentitiy
      
    }
    
    observe({
      session$sendCustomMessage(type = "commmemmsg" ,
                                message = list(id=memcommunity))
    })
  })
  
  # disease pathway table click
  observe({
    row <- input$plotgraph1_rows_selected
    val<-disptable[as.numeric(row),]
    if(is.null(val)){
      return(NULL)
    }
    z<-apply(val,1,function(x) which(x==max(x)))
    #print(rownames(z))
    last_selected_row = tail(row, n=1)
    
    
    #proteins<-protienDSpathway[protienDSpathway$Pathway==unlist(last_selected_row),]$Protein
    #print(proteins)
    session$sendCustomMessage(type = "commmemmsg" ,
                              message = list(id=paste(rownames(z),collapse=",")))
    
  })
  
  # table click
  observe({
    row <- input$entities_table_rows_selected
    if (length(row)) {
      session$sendCustomMessage(type = "commmemmsg" ,
                                message = list(id=global$nodes[row,1]))
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
    print("sigma node click");
    memcommunity <- NULL
    if (is_comm_graph){
      data <- peek_top(global$viz_stack)
      graph <- data[[1]]
      communities <- data[[2]]
      graph <- subgraph_of_one_community(graph, communities, input$comm_id) 
      communities <- get_communities(graph,input$select)
      global$viz_stack <- insert_top(global$viz_stack, list(graph, communities))
      global$name <- insert_top(global$name, input$comm_id)
      
      if(input$searchentitiy =="")
        return()
      
      searchelm=input$searchentitiy
      memcomm <- NULL
      
      if (vcount(graph) >  as.numeric(conf$community_threshold)) {
      # if (is_comm_graph){
        ii<-1
        for(elm in unlist(searchelm)){
          if(length(which(elm== V(graph)$name)) != 0){
            memcomm[ii] <-  communities$membership[which(elm== V(graph)$name)]
            ii<-ii+1
          }
        }
        memcommunity<-paste(memcomm,collapse = ",")
      } else {
        memcommunity <- input$searchentitiy
      }
      
    }
    else {
      memcommunity <- input$searchentitiy
    }
    
    print(memcommunity)
    observe({
      session$sendCustomMessage(type = "commmemmsg" ,
                                message = list(id=memcommunity))
    })
    
  })
  
  resetgraph<-function(conf)
  {
    graph <- build_initial_graph(conf)
    is_comm_graph <- TRUE
    communities <- get_communities(graph,input$select)
    global$viz_stack <- rstack()
    global$viz_stack <- insert_top(global$viz_stack, list(graph, communities))
    global$name <- insert_top(s2, "")
    
    x<-as.data.frame(conf$Interactions)
    
    z<-c()
    itr<-1
    for(ii in x$Entity1){
      pastestr=paste0(ii,"-",x$Entity2[itr],sep="")
      z[itr] <- c(pastestr=pastestr)
      itr<-itr+1
    }
    z[itr] <- paste0("all"="All")
    updateRadioButtons(session,"interactions",label="Show Interactions:",choices=z,selected="All")
    
    print(input$community_col)
  }
  
  processrow<-function (elm)
  {
    p(paste(toString(elm[1]), "'s are ",sep=""), span(toString(elm[2]), style = paste("color:",toString(elm[2]),sep="")))
  }
  
  # update the summary stats
  update_stats <- function(graph, is_comm_graph){
    nodes <- get.data.frame(graph, what="vertices")
    nodes$degree <- degree(graph)
    nodes$pagerank <- page_rank(graph)$vector
    # if (is_comm_graph==TRUE){
    #   colnames(nodes) <- c("Name", "Type", "Comm", "Size", "Degree","PageRank")
    # } else {
    #   colnames(nodes) <- c("Name", "Type", "Comm", "Degree","PageRank")
    # }
    global$nodes <- nodes
  }
  
  # writes out the current viz graph to a json for sigma
  graph_to_write <- reactive({
    print("graph_to_write")
    data <- peek_top(global$viz_stack)    
    graph <- data[[1]]
    graphdf <- get.data.frame(graph, what="vertices")
    communities <- data[[2]]
    print(paste("is_comm_graph=",is_comm_graph))
    # Try and apply community detection if there are a lot of nodes to visualize
    if (vcount(graph) >  as.numeric(conf$community_threshold)) {
      print("apply community detection")
      community_graph <- get_community_graph(graph, communities)
      commdf <- get.data.frame(community_graph, what="vertices")
      if (vcount(community_graph) > 1){ 
        is_comm_graph <<- TRUE
        return(list(community_graph, TRUE))
      }
    } 
    
    # If we have few enough nodes (or would have just 1 (sub)community) visualize as is
    V(graph)$size <- 1
    is_comm_graph <<- FALSE
    
    # Remove nodes we aren't we don't want that type of node    
    dellist <- c()
    indx <- 1
    
    return(list(graph, FALSE))
  })
  
}

