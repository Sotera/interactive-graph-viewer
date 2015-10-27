## ui.R ##
library(shiny)

shinyUI(
  fluidPage(theme="custom.css",
            tags$head(
              tags$link(rel = "stylesheet", type = "text/css", href = "custom.css"),
              tags$script(src='lib/sigma.min.js'),
              tags$script(src='lib/sigma.layout.forceAtlas2.min.js'),
              tags$script(src='lib/sigma.parsers.json.min.js')
            ),
            
            # Page title
            tags$h3("Community Visualization v2.0"),
            p("Communities are ", span("blue", style = "color:#2A9FD6"), 
              ", proteins are ",  span("green", style = "color:#77B300"),
              ", chemicals are ", span("orange", style = "color:#FF8800"), 
              ", and diseases are ", span("red", style = "color:#CC0000")
              ),
            
            # headers
            fluidRow(
              column(6, tags$h3("Network", align = "left")),
              column(6, tags$h3("Details", align = "left"))
            ),
            
            #extra buttons
            
            fluidRow(
              actionButton("reset_button", "Reset")
              ),
            
            # graphs
            fluidRow(
              column(6, 
                     tags$canvas(id="graph", # graphical output area
                                 width="1000",
                                 height="800"),
                     uiOutput("graph_with_sigma")
              )
            )
                     
            
            # end of page
  )
)


