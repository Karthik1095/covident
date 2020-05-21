filterPanel <- wellPanel(
  id = "searchpanel",
  p(strong("Filter Options"), br(), "Any combination of filters accepted."),
  selectInput(inputId = "journal", label="Journal", choices = NULL, multiple = TRUE),
  div(style = "margin-top:-15px"),
  selectInput(inputId = "study", "Type of Research", choices = NULL, multiple = TRUE),
  div(style = "margin-top:-15px"),
  selectInput(inputId = "author", "Author(s)",choices = NULL, multiple = TRUE),
  div(style = "margin-top:-15px"),
  selectInput(inputId = "specialty", "Specialty",choices = NULL, multiple = TRUE),
  div(style = "margin-top:-15px"),
  selectInput(inputId = "rating", "Newsworthiness Rating (1 - 7)",choices = NULL, multiple = TRUE),
  div(style = "margin-top:-15px"),
  selectInput(inputId = "relevancerating", "Clinical Practice Relevance Rating (1 - 7)",choices = NULL, multiple = TRUE),
  div(style = "margin-top:-15px"),
  shinyWidgets::radioGroupButtons(inputId="specSwitch", size="sm", label="Specialty matches:", choices=c("Any term", "All terms"), selected="Any term", status="info"),
  div(style = "margin-top:-10px"),
  hr(),
  div(style = "margin-top:-15px"),
  p(textOutput("N", inline = TRUE), " result(s)."),
  fluidRow(
    column(6,shinyWidgets::dropdown(
      downloadButton(outputId = "export", label = "CSV", class="btn-secondary btn-sm"),
      status="btn-primary btn-sm",
      size="sm",
      label="Download"
    )),
    column(6, actionButton(inputId = "clearAll", "Clear", class="btn-primary btn-sm"))
  )
)

ui <- navbarPage(
  title = 'Covid Evidence for Dentists',
  position = c("fixed-top"), inverse = TRUE, 
  tabPanel(
      'Included',
      id="tab-panel",
      shinyjs::useShinyjs(),
      fluidRow(
        column(3, 
              filterPanel,
               wellPanel(
                   style = "overflow-y:auto; max-height:350px", htmlOutput("ref_caption"))
        ),
        column(9, DT::dataTableOutput('ex1'))
      )
  ),
  tabPanel('Summary Of Evidence',
           tags$style(type="text/css","body {padding-top:90px;}"),
           fluidRow(column(3),
                    column(6,wellPanel(
                          HTML(includeMarkdown("markdown/Summary.md")),
                          img(src="Prisma.png",width="100%"),
                          HTML(includeMarkdown("markdown/Summary1.md")),
                          img(src="Traige.png",width="100%"),
                          HTML(includeMarkdown("markdown/Summary2.md")),
                          img(src="wait.png",width="100%"),
                          HTML(includeMarkdown("markdown/Summary3.md")),
                                       )),
                    column(3))
  ),

      tabPanel("The Project",
           tags$style(type="text/css","body {padding-top:90px;}"),
           fluidRow(column(3),
              column(6,wellPanel(
                HTML(includeMarkdown("markdown/About-Proj.md"))
              )),
             column(3))
    ),
    tabPanel('Methods',
             tags$style(type="text/css","body {padding-top:90px;}"),
             fluidRow(column(3),
                    column(6,wellPanel(HTML(includeMarkdown("markdown/Methods.md")),
                                       )),
                    column(3))
    ),
  tabPanel('About Us',
           tags$style(type="text/css","body {padding-top:90px;}"),
           fluidRow(column(3),
                    column(6,wellPanel(
                      HTML(includeMarkdown("markdown/About-us.md")),
                    )),
                    column(3))
  ),
  collapsible = TRUE,
  theme = "yeti.css",
  header = tags$head(includeHTML(("google-analytics.html")), tags$link(rel="shortcut icon", href="favicon.ico"))
)
