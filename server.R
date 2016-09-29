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
graph <- build_initial_graph(conf)
communities <- get_communities(graph)
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
uniqueentities <<- NULL


function(input, output, session){ 
  global <- reactiveValues()
  
  global$viz_stack <- insert_top(s1, list(graph, communities))
  global$name <- insert_top(s2, "")
  
  
  
  output$contents <- renderTable({
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
  
  observeEvent(input$entitymapping_button, {
    inFile <- input$file1
    dat <- read.csv(inFile$datapath, header = input$header,
                    sep = input$sep, quote = input$quote)
    print(input$type1)
    x<-paste(dat[,"type1"],dat[,"type2"],collapse = ",",sep=",")
    uniqueentities<<-unique(unlist(strsplit(x,",")))
    updateSelectInput(session,"entcolors",choices = uniqueentities)
    updateSelectInput(session,"entintr1",choices=uniqueentities)
    updateSelectInput(session,"entintr2",choices=uniqueentities)
  })
  
  
  #set entity color button
  observeEvent(input$entdone,{
    print(uniqueentities)
    colormapping <<- rbind(colormapping,data.frame(Entity=toString(input[["entcolors"]]),Color=toString(input[["entcol"]])))
    output$enttable <- renderTable(colormapping)
  })
  
  
  #set entity interacton button
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
  
  resetgraph<-function(conf)
  {
    graph <- build_initial_graph(conf)
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
    output$legend<- renderUI({
      
      cm<-p("Communities are ", span(input$community_col, style = paste("color:",input$community_col,sep="")))
      z<-apply(colormapping,1, processrow)
      return(append(z,cm))
    })
    
    
    
  }
  
  processrow<-function (elm)
  {
    p(paste(toString(elm[1]), "'s are ",sep=""), span(toString(elm[2]), style = paste("color:",toString(elm[2]),sep="")))
  }
  
  observeEvent(input$variable, {
    #print(input$variable)
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
    print(rownames(z))
    last_selected_row = tail(row, n=1)
    
    
    #proteins<-protienDSpathway[protienDSpathway$Pathway==unlist(last_selected_row),]$Protein
    #print(proteins)
    session$sendCustomMessage(type = "commmemmsg" ,
                              message = list(id=paste(rownames(z),collapse=",")))
    
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
      if (is_comm_graph){
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
      observe({
        session$sendCustomMessage(type = "commmemmsg" ,
                                  message = list(id=memcommunity))
      })
      
      
      
    }
  })
  
  # writes out the current viz graph to a json for sigma
  graph_to_write <- reactive({
    data <- peek_top(global$viz_stack)    
    graph <- data[[1]]
    communities <- data[[2]]
    print(is_comm_graph)
    # Try and apply community detection if there are a lot of nodes to visualize
    if (vcount(graph) >  as.numeric(conf$community_threshold)){
      community_graph <- get_community_graph(graph, communities)
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
    
    if(input$interactions == "All")
      return(list(graph, FALSE))
    
    for(nd in V(graph)){
      
      atr <- get.vertex.attribute(graph,"type",nd)
      print(atr)
      if(grepl(atr,input$interactions) == FALSE){
        dellist[indx] <- nd
        indx <- indx+1
      }
      
    }
    graph <- delete.vertices(graph,dellist)
    
    return(list(graph, FALSE))
  })
  
  # render with sigma the current graph (in json)
  output$graph_with_sigma <- renderUI({
    data <- graph_to_write()
    print("printing conf")
    print(conf)
    makenetjson(data[[1]], "./www/data/current_graph.json", data[[2]],conf) 
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
      colnames(nodes) <- c("Name", "Type", "Comm", "Size", "Degree","PageRank")
    } else {
      colnames(nodes) <- c("Name", "Type", "Comm", "Degree","PageRank")
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
      table <- global$nodes[c("Name", "Degree","PageRank")]
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
  
  output$plotgraph1 <-DT::renderDataTable({
    protienDSpathway<<-data.frame()
    sortedlabel<-NULL
    #labelfreq <- lapply(rawlabels,table)
    proteins<-global$nodes[global$nodes$Type=="Protein","Name"]
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
  selection = "single")
  
  
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
}
