## ui.R ##
library(DT)
library(shiny)
library(shinydashboard)


header <- dashboardHeader(title = "Community Visualization v2.0")

sidebar <- dashboardSidebar(
  p("Communities are ", span("blue", style = "color:#2A9FD6")), 
  p("Proteins are ",  span("green", style = "color:#77B300")),
  p("Chemicals are ", span("orange", style = "color:#FF8800")), 
  p("Diseases are ", span("red", style = "color:#CC0000")),
  actionButton("reset_button", "Reset")
)

body <- dashboardBody(
  tags$head(
    tags$script(src='lib/sigma.min.js'),
    tags$script(src='lib/sigma.layout.forceAtlas2.min.js'),
    tags$script(src='lib/sigma.parsers.json.min.js')
  ),
  
  fluidRow(  
    box( title = "Network",
         header = TRUE,
         tags$canvas(id="graph", # graphical output area
                     width="1000",
                     height="800"),
         uiOutput("graph_with_sigma")
    ),
    
    tabBox( title = "Details", 
         id = "details",
         selected = "Tab1",
         tabPanel("Tab1", DT::dataTableOutput("degree_table")),
         tabPanel("Tab2", plotOutput("degree_distribution"))
    )
  )
  
)

dashboardPage(header, sidebar, body)




# shinyUI(
#   fluidPage(theme="custom.css",
#             tags$head(
#               tags$link(rel = "stylesheet", type = "text/css", href = "bootstrap-darkly.css"),
#               tags$script(src='lib/sigma.min.js'),
#               tags$script(src='lib/sigma.layout.forceAtlas2.min.js'),
#               tags$script(src='lib/sigma.parsers.json.min.js')
#             ),
#             
#             # Page title
#             tags$h3("Community Visualization v2.0"),
#             p("Communities are ", span("blue", style = "color:#2A9FD6"), 
#               ", proteins are ",  span("green", style = "color:#77B300"),
#               ", chemicals are ", span("orange", style = "color:#FF8800"), 
#               ", and diseases are ", span("red", style = "color:#CC0000")
#               ),
#             
#             # headers
#             fluidRow(
#               column(6, tags$h3("Network", align = "left")),
#               column(6, tags$h3("Details", align = "left"))
#             ),
#             
#             #extra buttons
#             
#             fluidRow(
#               actionButton("reset_button", "Reset")
#               ),
#             
#             # graphs
#             fluidRow(
#               column(6, 
#                      tags$canvas(id="graph", # graphical output area
#                                  width="1000",
#                                  height="800"),
#                      uiOutput("graph_with_sigma")
#               ),
#               column(6,
#                      DT::dataTableOutput("degree_table"),
#                      plotOutput("degree_distribution"))
#             )
#                      
#             
#             # end of page
#   )
# )
# 
# 
