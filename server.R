#server.R
library(shiny)
#library(shinydashboard)

function(input, output, session){ 
  
  output$dynamic_subgraph <- renderUI({
    id = input$comm_id
    if (!is.null(id)){      
      # generate a new html file from the template with the correct community
      cmd = paste("sed 's/COMM_ID/", id, "/' ", subgraph_template_html, " > ", subgraph_html, sep='')
      system(cmd, wait=TRUE)
      print(cmd)
      return(includeHTML(subgraph_html))
      #tags$iframe(src = "subgraph.html")
    } 
    else {
      return(NULL)
    }
  })
  
  output$subgraph_title <- renderUI({
    id <- input$comm_id
    if (!is.null(id)){
      text = paste("Community ", id, " in detail", sep = "")
      return(tags$h3(text, align="center"))
    }
    else{
      return("")
    }
  })
    #tags$h3("Community X in detail", align = "center"))
  output$test_string <- renderText({paste("test ", input$comm_id)})
  
}
