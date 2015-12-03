## ui.R ##
library(DT)
library(shiny)
library(shinydashboard)


header <- dashboardHeader(title = "Community Visualization v2.0", titleWidth = 450)

sidebar <- dashboardSidebar(
  p("Communities are ", span("blue", style = "color:#2A9FD6")), 
  p("Proteins are ",  span("green", style = "color:#77B300")),
  p("Chemicals are ", span("orange", style = "color:#FF8800")), 
  p("Diseases are ", span("red", style = "color:#CC0000")),

  actionButton("back_button", "Back"),
  actionButton("reset_button", "Reset"),  
  radioButtons("interactions", "Show interactions:",
               c("All" = "all",
                 "Protein-Protein" = "Protein-Protein",
                 "Protein-Disease" = "Protein-Disease",
                 "Protein-Chemical" = "Protein-Chemical",
                 "Chemical-Disease" = "Chemical-Disease"))
)

body <- dashboardBody(
  tags$head(
    tags$script(src='lib/sigma.min.js'),
    tags$script(src='lib/sigma.layout.forceAtlas2.min.js'),
    tags$script(src='lib/sigma.parsers.json.min.js')
  ),
  
  fluidRow(  
    box(     textOutput("name"), 
             uiOutput("graph_with_sigma"),
             title = "Network",
         header = TRUE,
         tags$canvas(id="graph", # graphical output area
                     width="1000",
                     height="800")
    ),
    
    tabBox( title = "Details", 
         id = "details",
         selected = "Entities",
         tabPanel("Entities", DT::dataTableOutput("degree_table")),
         tabPanel("Degrees", plotOutput("degree_distribution")),
         tabPanel("PageRanks", plotOutput("pagerank_distribution"))
    )
  )
  
)

dashboardPage(header, sidebar, body)

