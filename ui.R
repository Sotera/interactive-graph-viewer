library(DT)
library(shiny)
library(plotly)
library(shinydashboard)
library(colourpicker)

header <- dashboardHeader(
  title = "Community Visualization v2.0",
  titleWidth = 300
)

body <- dashboardBody(
  
  tags$head(tags$style(HTML('
    .skin-blue .main-header .logo {
      background-color: #3c8dbc;
    }
    .skin-blue .main-header .logo:hover {
      background-color: #3c8dbc;
    }
  '))),
  
  fluidRow(
    column(width=12,
      tabsetPanel(
        id='tabvals',
        tabPanel(
          'Viewer',
          fluidRow (
            column(9,
              # textOutput("name"),
              # tags$style(type="text/css", "#name {background-color: white; margin: 5px}"),
              box(width = NULL,
                  textOutput("name"),
                  id = "graphbox",
                  tags$div(id="graph2"),
                  tags$style(type="text/css", "#graphbox {height: 550px; max-height: 900px; margin: auto;}"),
                  uiOutput("graph_with_sigma")
              ),
              box(width = NULL,
                tabsetPanel(
                  id = "details",
                  selected = "Entities",
                  tabPanel("Entities", DT::dataTableOutput("degree_table")),
                  tabPanel("Degrees", plotlyOutput("degree_distribution")),
                  tabPanel("PageRanks", plotlyOutput("pagerank_distribution")),
                  tabPanel("Disease Pathway", 
                    tabBox(
                     width=500,title="",
                     id="pathinfo",
                     tabPanel(
                       "Data",
                       fluidRow(
                         splitLayout(
                           cellWidths = c("100%", "0%"),
                           DT::dataTableOutput("plotgraph1")
                         )
                       )
                     )
                     # tabPanel("Heatmap",plotlyOutput("plotgraph2"))
                    )
                  )
                )
              )
            ),
            column(3,
                   
              box(width = NULL,
                status = "warning",
                selectInput("select",
                  label = "Algorithm",
                  choices = list(
                   "Louvain" = "lv",
                   "Walktrap" = "wk",
                   "Fast Greedy" = "fg",
                   "Infomap" = "imap",
                   "Edge betweeness" = "ebetweens",
                   "Label Propagation"="lp",
                   "Spinglass"="sg"
                  ),
                  selected = "lv"
                ),
                actionButton("back_button", "Back"),
                tags$style(type="text/css", "#back_button {float: left; margin: 5px;}"),
                actionButton("reset_button", "Reset"),
                tags$style(type="text/css", "#reset_button {float: left; margin: 5px;}")
              ),
              box(width = NULL,
                status = "warning",
                uiOutput("choose_entTypes")
              ),
              box(width = NULL,
                status = "warning",
                textInput("searchentitiy","Search Entity"),
                actionButton("search_button","Search")
              ),
              box(width = NULL,
                  solidHeader = TRUE,
                  uiOutput("legend")
              )
            )
          ),
          value=2
        ),
        tabPanel(
          'Configuration Options',
          tabBox(
            width=500,
            title="",
            id="fileinfo",
            tabPanel(
              "EdgeListFile",
              fileInput(
                'file1',
                'Choose file to upload',
                accept = c(
                  'text/csv',
                  'text/comma-separated-values',
                  'text/tab-separated-values',
                  'text/plain',
                  '.csv',
                  '.tsv'
                )
              ),
              tags$hr(),
              checkboxInput('header', 'Header', TRUE),
              radioButtons('sep', 'Separator',
                c(Comma=',',
                 Semicolon=';',
                 Tab='\t'),
                ','),
              radioButtons('quote', 'Quote',
                c(None='',
                 'Double Quote'='"',
                 'Single Quote'="'"),
                '"'),
              tags$hr(),
              p('File size limit is 100MB')
            ),
            tabPanel("Entity definitions",
              selectInput("entity1","Entity1 Column:",c()),
              selectInput("entity2","Entity2 Column:",c()),
              selectInput("type1","Entitiy1 Type Column:",c()),
              selectInput("type2","Entity2 Type Column:",c()),
              actionButton("entitymapping_button", "Done")
            ),
            tabPanel("Define Entity interactions",
              selectInput("entintr1","Select entity 1",choices=c()),
              selectInput("entintr2","Select entity 2",choices=c()),
              actionButton("entintrdone","Assign interaction"),
              tableOutput("entintrtable")
            ),
            tabPanel("Entity colors",
              selectInput("entcolors","Select entity",choices=c()),
              colourInput("entcol","Select entity color"),
              actionButton("entdone","Assign color"),
              tableOutput("enttable")
            ),
            tabPanel("Community parameters",
              colourInput("community_col","Community Color","#2ADDDD"),
              numericInput("comm_size","Max. community size:",value = 400)
            )
          ),
          actionButton("saveoptionscsv","Save"),
          mainPanel(
            tableOutput('contents')
          ),
          value=1
        )
      )
    ) 
  ),
  tags$script(src='lib/sigma.min.js'),
  tags$script(src='lib/sigma.layout.forceAtlas2.min.js'),
  tags$script(src='lib/sigma.parsers.json.min.js'),
  tags$script(src='rendergraph.js'),
  tags$link(rel = "stylesheet", type = "text/css", href = "graph.css")
)

dashboardPage(
  header,
  dashboardSidebar(disable = TRUE),
  body
)
