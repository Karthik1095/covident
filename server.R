# Executes once per service start
library(dplyr)

#Case formatting from https://stat.ethz.ch/R-manual/R-devel/library/base/html/chartr.html
capwords <- function(s, strict = FALSE) {
  cap <- function(s) paste(toupper(substring(s, 1, 1)),
                           {s <- substring(s, 2); if(strict) tolower(s) else s},
                           sep = "", collapse = " " )
  sapply(strsplit(s, split = " "), cap, USE.NAMES = !is.null(names(s)))
}

#Create a PubMed link in HTML
createLink <- function(PMID, text) {
  sprintf('<a href="https://www.ncbi.nlm.nih.gov/pubmed/%s" target="_blank"><b>%s</b></a>', PMID, text)
}

included.headers <- c("Title - Linked","Author", "Journal", "Specialty", "Type of Study","NewsworthinessRating" ,"RelevanceRating")

# Update the data once
link <- list.files("data/", pattern="(current)", full.names=TRUE)[1]

# Data Processing (done once)
rawtable <- read.csv(link, sep = ",", na.strings="", encoding = "UTF-8", check.names=FALSE, stringsAsFactors=FALSE, colClasses = "character")
#rawtable <- rawtable %>% select(-"")
print(rawtable)
headers <- colnames(rawtable)

# Deduplicate entries, merging the specialties and type bucket
filtered.table <- data.frame(AuthorList=c(), PMID=c(), Author=c(), Journal=c(), 'Type of Study'=c(),  Title=c(), specialty_raw=c(), NewsworthinessRating=c(), RelevanceRating=c(), stringsAsFactors = FALSE, check.names = FALSE)

unique_refs <- unique(rawtable$Refid)
for (i in 1:length(unique_refs)) {
  group <- (rawtable %>% filter(Refid == unique_refs[i])) # separate out the reviews of the same reference
  group_spec <- group %>% select(starts_with("Spec"))
  vec_spec <- c()

  
  for (j in 1:nrow(group)) { #iterate through the reviews of the reference and create a list of (specialty) values and (type bucket) values
    vec_spec <- c(vec_spec, group_spec[j,])
  }
  
  specialties <- unique(as.vector(unlist(vec_spec))) # get unique entries as vector
  specialties <- specialties[!is.na(specialties)]
  
  authors <- lapply(strsplit(as.character(group$Author[1]), ","),trimws)
  
  
  # Fill filtered.table with useful data
  temp <- data.frame(AuthorList=I(authors), PMID=group$PMID[1],Author=group$Author[1], Journal=capwords(group$Journal[1]), 'Type of Study'=group$`Type of Study`[1], Title=group$Title[1], NewsworthinessRating=group$NewsworthinessRating[1], RelevanceRating=group$RelevanceRating[1], specialty_raw=I(list(specialties)), stringsAsFactors = FALSE,check.names = FALSE)
  filtered.table <- rbind(filtered.table, temp)
}

N <<- nrow(filtered.table)

#Create filter choices
unique.authors <- sort(unique(unlist(filtered.table$AuthorList)))
unique.authors <<- unique.authors[lapply(unique.authors, nchar) > 0]
unique.journals <- sort(unique(filtered.table$Journal))
unique.studytypes <<- sort(unique(filtered.table$'Type of Study'))
unique.specialties <<- sort(c("General dentistry","Pedodontics","Conservative Dentistry and Endodontics","Oral and Maxillofacial Surgery","Dental Public Health","Oral Medicine","Orthodontics","Prosthodontics","Periodontics"))
unique.rating <<- sort(c("1","2","3","4","5","6","7"))
unique.relevancerating <<- sort(c("1 - Definitely not relevant","2 - Probably not relevant","3 - Possibly not relevant","4 - Possibly relevant:likely of indirect","5 - Possibly relevant","6 - Definitely relevant","7 - Highly relevant"))


# Aesthestics for Shiny
filtered.table$Specialty <- lapply(filtered.table$specialty_raw, function(x) paste(x, collapse = ", "))
filtered.table$Author <- unlist(lapply(filtered.table$AuthorList, function(x) if (length(x) > 3) paste(paste(x[1:3], collapse = ", "), "et al") else paste(x, collapse = ", ")))

#############################################

server <- function(input, output, session) { # Executes once per session (no need to restart service)
  #Populate the search filters
  updateSelectInput(session, "journal", choices = c("Select a journal" = "", unique.journals))
  updateSelectInput(session, "author", choices = c("Select authors" = "", unique.authors))
  updateSelectInput(session, "study", choices = c("Select a research type" = "", unique.studytypes))
  updateSelectInput(session, "specialty", choices = c("Select an area of interest" = "", unique.specialties))
  updateSelectInput(session, "rating", choices =c("select Newsworthiness rating"="",unique.rating))
  updateSelectInput(session, "relevancerating", choices =c("select Relevance rating"="",unique.relevancerating))
  
  # Parse URI
  observe({
    query <- parseQueryString(session$clientData$url_search)
    if (!is.null(query[['specialty']])) {
      if (query[['specialty']] %in% unique.specialties) updateTextInput(session, "specialty", value = query[['specialty']])
    }
  })
  
  
  # Get a local copy of the dataset
  display.table <- filtered.table
  
  #clear all button actions
  observeEvent(input$clearAll, {
    shinyjs::reset("searchpanel")
  })

  #Main Data Output
  output$ex1 <- DT::renderDataTable(server=TRUE, {
    #Filter Journal
    if (!is.null(input$journal)) {
      display.table <- display.table[display.table$Journal %in% input$journal,]
    }
    #Filter Rating
    if (!is.null(input$rating)) {
      display.table <- display.table[display.table$NewsworthinessRating %in% input$rating,]
    }
    
    #Filter RelevanceRating
    if (!is.null(input$relevancerating)) {
      display.table <- display.table[display.table$RelevanceRating %in% input$relevancerating,]
    }
    
    #Filter Study
    if (!is.null(input$study)) {
      display.table <- display.table[display.table$"Type of Study" %in% input$study,]
    }

    #Filter Authors
    if (!is.null(input$author) & nrow(display.table) > 0) {
      #Initialize FALSE Vector
      v <- vector("logical",nrow(display.table))
      #iterate over author rows and flag as TRUE if any of the selected authors present
      for (i in 1:length(v)) {
        for (query in input$author) {
          if (query %in% display.table$AuthorList[[i]]) v[i] <- TRUE; break
        }
      }
      display.table <- display.table[v,]
    }
    
    # Filter Specialty
    if (!is.null(input$specialty) & nrow(display.table)) {
      #Initialize FALSE Vector
      v <- vector("logical",nrow(display.table))
      if (input$specSwitch == "Any term"){
      #iterate over author rows and flag as TRUE if ANY of the selected authors present
        for (i in 1:nrow(display.table)) {
          for (query in input$specialty) {
            if (query %in% display.table$specialty_raw[[i]]) v[i] <- TRUE; break
          }
        }
      } else { #iterate over author rows and flag as TRUE if ALL of the selected authors present
        for (i in 1:nrow(display.table)) {
          if (all(sapply(input$specialty, function(x) x %in% display.table$specialty_raw[[i]]))) v[i] <- TRUE
        }
      }
      display.table <- display.table[v,]
    }

    #Caption rendering
    output$ref_caption <- renderUI(
      if (!is.null(input$ex1_rows_selected)) {
        HTML(paste0(
          display.table$Author[input$ex1_rows_selected], ". ",
          "<b>",display.table[input$ex1_rows_selected,"Title - Linked"], "</b> ",
          "<i>", trimws(display.table[input$ex1_rows_selected,"Journal"]), "</i>. <br><br>"
        ))} else HTML("<i>Select a reference...</i>")
    )
    
    output$N <- renderText(nrow(display.table))
    
    #Create Links
    display.table$'Title - Linked' <-  createLink(display.table$PMID, display.table$Title)

    #Export option
    output$export <- downloadHandler(
      filename = function() {
        paste("references",Sys.Date(),".csv", sep = "")
      },
      content = function(file) {
        write.csv(display.table[,c("Title", "Author", "Journal")], file, row.names = FALSE)
      }
    )
    
    #Output
    DT::datatable(
      display.table[,included.headers],
      colnames = c("Title" = "Title - Linked", "Type of Research"="Type of Study","Newsworthiness Rating (1 - 7)"="NewsworthinessRating","Clinical Practice Relevance Rating (1 - 7)"="RelevanceRating"),
      extensions = "Responsive",
      options = list(pageLength = 10, order = list(list(4, "desc"))),
      rownames= FALSE, escape=-1, selection = 'single')
  })
}
