library(shiny)
library(shinydashboard)
library(tidyverse)
library(ggplot2)
library(dplyr)

df <- read.csv("data/airscan_data_r.csv", stringsAsFactors = FALSE)