library(shiny)
library (DT)
library(tidyverse)
library(shinyWidgets)
library(shinythemes)
library(anytime)

source("ui.R")
source("server.R")

# Run the application 
shinyApp(ui = ui, server = server)
