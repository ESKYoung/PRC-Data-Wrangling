# ESK Young
# PRC Data Wrangling

# This R script complies Excel-based versions of the published Police Recorded 
# Crime Open Data Tables into a single data frame, and outputs this into a CSV 
# file.

# The Police Recorded Crime Open Data Tables are available here: 
# www.gov.uk/government/statistics/police-recorded-crime-open-data-tables

# The code relies on the data having the following column names, in the
# following order:

#   Financial Year
#   Financial Quarter
#   Force Name
#   CSP Name
#   Offence Description
#   Offence Group
#   Offence Subgroup
#   Offence Code
#   Number of Offences

# Initialisation ---------------------------------------------------------------

# Clear the environment
rm(list = ls())

# Load required libraries
library(data.table)
library(magrittr)
library(readxl)
library(zoo)

# Define the folder containing raw data
dir.raw <- "01 Raw Data"

# Define the filename for unification of force, CSP, offence group, and offence 
# subgroup names
kUniForce <- "2017-08-10 Unified Force Names.csv"
kUniCSP <- "2017-08-10 Unified CSP Names.csv"
kUniOffGrp <- "2017-08-10 Unified Offence Groups.csv"
kUniOffSubGrp <- "2017-08-10 Unified Offence Subgroups.csv"

# Define the filename for the merged CSP names
kMergedCSP <- "2017-08-10 Merged CSP Names.csv"

# Start timer ------------------------------------------------------------------

# Start a timer
kTimeStart <- proc.time()

# Locate raw data files --------------------------------------------------------

# Find all the files with an Excel extension in the raw data folder
kRawFnames <- list.files(path = dir.raw, 
                         pattern = c(".xlsx", ".xls"),
                         full.names = TRUE)

# Import raw data --------------------------------------------------------------

# Use nested "lapply" functions to import all tabs from all Excel files listed 
# "kRawFnames", and then use "rbindlist" function to collapse them all down into
# a single data.table.
data.raw <- lapply(kRawFnames, 
                   function(xx) { 
                     lapply(excel_sheets(xx),
                            read_excel,
                            path = xx) %>%
                       rbindlist(.)
                   }) %>%
  rbindlist(.)

# Make the column headers syntatically valid
names(data.raw) <- make.names(names(data.raw), unique = TRUE)
 
# Import unification files -----------------------------------------------------

# Create a character vector concatenating the four unification files
kUniFileNames <- c(kUniForce, kUniCSP, kUniOffGrp, kUniOffSubGrp)

# Create a character vector containing the names of each of the four unification
# files
kUniNames <- c("Force", "CSP", "OffGrp","OffSubGrp")

# Import each of the unification files, and set them as data.tables
list.uni <- lapply(file.path(dir.raw, kUniFileNames),
                   function (x) {
                     as.data.table(read.csv(x))
                   })

# Rename the elements within "list.uni"
names(list.uni) <- kUniNames

# Import the merged CSP information file ---------------------------------------

# Import the merged CSP file
data.mCSP <- read.csv(file = file.path(dir.raw, kMergedCSP))

# Standardise date formats -----------------------------------------------------

# Convert the values in the financial year and quarter columns to state a
# standard date format for the end of the financial quarter
data.raw$Date <- 
  substring(text = data.raw$Financial.Year,
            first = 1,
            last = 4) %>%  #  extracts the first year in the financial year
  paste(., (as.numeric(data.raw$Financial.Quarter))*3, "01", 
        sep = "-") %>%  #  converts the quarter into a month based on calendar 
  #  quarters
  as.yearmon(.) + 0.25  #  adds 3 months to base the month on financial quarters

# Drop unnecessary columns -----------------------------------------------------

# Drop the financial year, and quarter columns
data.raw[, c("Financial.Year", "Financial.Quarter"):=NULL]

# Add ID column ----------------------------------------------------------------

# Add an ID column for sorting later to preserve the order
data.raw[, ID := .I]

# Determine order of columns
kDataRawCol <- names(data.raw)

# Cleanse dataset --------------------------------------------------------------

# Cleanse the force names - set "Force.Name" as the key in "data.raw", and the 
# corresponding unification file, then cleanse the fields in "data.raw"
setkey(data.raw, "Force.Name")
setkey(list.uni$Force, "Force.Name")
data.raw[list.uni$Force, Force.Name := Unified.Force]

# Cleanse the CSP names - set "CSP.Name" as the key in "data.raw", and the 
# corresponding unification file, then cleanse the fields in "data.raw"
setkey(data.raw, "CSP.Name")
setkey(list.uni$CSP, "CSP.Name")
data.raw[list.uni$CSP, CSP.Name := Unified.CSP]

# Cleanse the offence groups - set "Offence.Group" as the key in "data.raw", and  
# the corresponding unification file, then cleanse the fields in "data.raw"
setkey(data.raw, "Offence.Group")
setkey(list.uni$OffGrp, "Offence.Group")
data.raw[list.uni$OffGrp, Offence.Group := Unified.Offence.Group]

# Cleanse the offence subgroups - set "Offence.Subgroup" as the key in  
# "data.raw", and the corresponding unification file, then cleanse the fields in 
# "data.raw"
setkey(data.raw, "Offence.Subgroup")
setkey(list.uni$OffSubGrp, "Offence.Subgroup")
data.raw[list.uni$OffSubGrp, Offence.Subgroup := Unified.Offence.Subgroup]

# Label merged CSPs ------------------------------------------------------------

# Merge "data.raw" with "data.mCSP" so the information is listed in the dataset
data.raw <- merge(data.raw, data.mCSP[, !(names(data.mCSP) %in% "Change")], 
                  by = "CSP.Name",
                  all.x = TRUE,
                  sort = FALSE)

# Check that all CSPs have been mapped
stopifnot(all(!is.na(data.raw$Mapped.CSP)))

# Sort the dataset -------------------------------------------------------------

# Sort the dataset, then drop the ID column
data.raw <- data.raw[order(ID)]
data.raw[, ID := NULL]

# Re-order the columns in "data.raw"
setcolorder(data.raw, c(kDataRawCol[kDataRawCol %in% names(data.raw)], 
                        names(data.raw)[!(names(data.raw) %in% kDataRawCol)]))

# Aggregate by the Offence Subgroup-level --------------------------------------

# Aggregate the dataset at the offence subgroup-level, whilst dropping the 
# offence description and code columns
data.agg <- names(data.raw)[!(names(data.raw) %in% c("Offence.Description", 
                                                     "Offence.Code",
                                                     "Number.of.Offences"))] %>%
  data.raw[, list(Number.of.Offences = sum(Number.of.Offences)), by = .]

# AQA - check that all crimes have been aggregated
stopifnot(sum(data.raw$Number.of.Offences) == sum(data.agg$Number.of.Offences))

# Finalisation -----------------------------------------------------------------

# Drop "." from all the column names
names(data.raw) <- gsub("[.]"," ", names(data.raw))
names(data.agg) <- gsub("[.]"," ", names(data.agg))

# Export the dataset -----------------------------------------------------------

# Export the raw dataset as a .Rdata file for further R Shiny work
saveRDS(object = data.raw,
        file = "Raw PRC Data.Rdata")

# Export the aggregated dataset as a .Rdata file for further R Shiny work
saveRDS(object = data.agg,
        file = "Aggregated PRC Data.RData")

# Export the aggregated dataset as a .csv file for further Power BI work
write.csv(x = data.agg,
          file = "Aggregated PRC Data.csv",
          row.names = FALSE)

# End timer --------------------------------------------------------------------

# End the timer
kTimeEnd <- proc.time() - kTimeStart