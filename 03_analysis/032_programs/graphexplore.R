#-----------------------------------------------------------------------------------#
# ! Task 017: Create the graphs that will feed into the pdf
# Created by YNW on 08/19/2023
# Last modified by YNW on 08/19/2023
#-----------------------------------------------------------------------------------#
# CGD Color palette
# TEAL: #0B4C5b
# Gold: #FFB52C
# Gray: #85A5AD
# Light Teal: #006970
# Light Gray: #F3F6F7
# Dark Gray: #394649
# Teal Black: #1A272A

#-----------------------------------------#
# 0. Initial Parameters
#-----------------------------------------#

rm(list=ls())

## Set up (Do not removes)
list.of.packages <- c("tidyverse",
                      "ggplot2",
                      "ggtext",
                      "dplyr",
                      "showtext",
                      "extrafont", ## for font_import
                      "haven",
                      "zoo",
                      "stringr",
                      "ggtext",
                      "stringr",
                      "rmarkdown",
                      "readr",
                      "knitr",
                      "scales",
                      #                  "data.table",
                      "kableExtra", 
                      "ggforce",
                      "ggrepel",
                      #                   "fmsb",
                      #                    "readxl",
                      "sjlabelled",
                      "grid",
                      #                     "shadowtext",
                      "ggpubr",
                      "cowplot",
                      #                      "packcircles",
                      "statebins",
                      "bslib",
                      "htmltools",
                      "websocket",
                      "remotes"
)
#install.packages("packcircles")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]

# If package doesn't exist on local computer, install them
if(length(new.packages)) install.packages(new.packages)

#load all required packages
lapply(list.of.packages, require, character.only = TRUE)


### SET UP PATHS (Do not modify) ###
user <- Sys.getenv("USERNAME")

projectFolder <- paste0("C:/Users/", user, "/Github/GLAD")
inputFolder <- paste0(projectFolder,"/01_harmonization/013_outputs/WLD")


# For Graphs
font_add_google("Bitter")
font_add("Sofia Pro Black Az", paste0(projectFolder, "/03_output/template/Sofia Pro Black Az.otf"))
font_add("Sofia Pro Regular Az", paste0(projectFolder, "/03_output/template/Sofia Pro Regular Az.otf"))
showtext_auto()

head <- "Sofia Pro Black Az"
subhead <- "Sofia Pro Regular Az"
bod <- "Bitter"

# For RMarkdown file
# (make sure these fonts are downloaded on your local computer)
#font_import(paths=paste0(projectFolder,"/00_documentation/fonts"), pattern="Sofia", prompt=F)

font_import(pattern="Bitter", prompt=F)
font_import(pattern="Sofia", prompt=F)

windowsFonts(sans="Sofia Pro")
windowsFonts(sans="Bitter-Regular")
loadfonts(device = "win")
loadfonts(device="postscript")
choose_font(c("Sofia Pro", "Bitter-Regular"))

# Set colors
gold <- "#FFB52C"
teal <- "#0B4C5b"
gray <- "#85A5AD"
lteal <- "#006970"
lgray <- "#F3F6F7"
dgray <- "#394649"
tealblack <- "#1A272A"

# Color for graph headers
headcol <- "grey20"

# Whether or not to overwrite graphs
overwrite = FALSE

#-----------------------------------------#
# Load Data
#-----------------------------------------#
# Figure 1 (Types of violence) and 2 (Parent Punishment)
df <- read.csv(paste0(inputFolder,"/TIMSS_analysis_all.csv"))
scores <- read.csv(paste0(projectFolder,"/CLO_PANEL.csv"))
#-----------------------------------------#
# Get data
#-----------------------------------------#
test <- df %>% filter(male != -9)

#test %>% 
filtered_data <- test %>% 
  filter(region != "" & !is.na(region) & incomelevel != "HIC")

ggplot(filtered_data) + 
  geom_point(data = filtered_data %>% filter(year == 2019 & male==1), 
             aes(x = reorder(countrycode, bullying_c_all), y = bullying_c_all), 
             color = gold, shape =108,size=4) +
  geom_point(data = filtered_data %>% filter(year == 2023  & male==1), 
             aes(x = reorder(countrycode, bullying_c_all), y = bullying_c_all), 
             color = gold) +
  geom_point(data = filtered_data %>% filter(year == 2019 & male==0), 
             aes(x = reorder(countrycode, bullying_c_all), y = bullying_c_all), 
             color = teal, shape =108,size=4) +
  geom_point(data = filtered_data %>% filter(year == 2023  & male==0), 
             aes(x = reorder(countrycode, bullying_c_all), y = bullying_c_all), 
             color = teal) +
  facet_grid(region ~ ., scales = "free_y", space = "free_y")+
  coord_flip(clip = "off") +
  ylim(0, 1) + 
  theme_minimal() 

write.csv(filtered_data, , traitsAsDir = FALSE, csv2 = TRUE, row.names = FALSE, ...)



# Filter and reshape the data
makegraph <- function(var) {
filtered_data <- test %>% 
  filter(region != "" & !is.na(region) & incomelevel != "HIC") %>%
  pivot_wider(names_from = year, values_from = .data[[var]], names_prefix = "year_") %>%
  filter(!is.na(year_2019) | !is.na(year_2023))  # Remove rows where both years are NA

g <- ggplot(filtered_data) + 
  # Grey baseline segment from 0 to max value for each country
  geom_segment(aes(x = reorder(countrycode, xend = countrycode, 
                   y = 0, yend = pmax(year_2019, year_2023, na.rm = TRUE)), 
               color = "gray70", linewidth = 0.5, na.rm = TRUE) +
  
  # Male: Segment line between 2019 and 2023 values (ignoring NA)
  geom_segment(data = filtered_data %>% filter(male == 1 & !is.na(year_2019) & !is.na(year_2023)), 
               aes(x = countrycode, xend = countrycode, 
                   y = year_2019, yend = year_2023), 
               color = gold, linewidth = 0.7, na.rm = TRUE) +
  
  # Female: Segment line between 2019 and 2023 values (ignoring NA)
  geom_segment(data = filtered_data %>% filter(male == 0 & !is.na(year_2019) & !is.na(year_2023)), 
               aes(x = countrycode, xend = countrycode, 
                   y = year_2019, yend = year_2023), 
               color = teal, linewidth = 0.7, na.rm = TRUE) +
  
  # Male data points
  geom_point(data = filtered_data %>% filter(male == 1), 
             aes(x = reorder(countrycode, year_2019), y = year_2019), 
             color = gold, shape = 108, size = 4, na.rm = TRUE) +
  geom_point(data = filtered_data %>% filter(male == 1), 
             aes(x = reorder(countrycode, year_2023), y = year_2023), 
             color = gold, na.rm = TRUE) +
  
  # Female data points
  geom_point(data = filtered_data %>% filter(male == 0), 
             aes(x = reorder(countrycode, year_2019), y = year_2019), 
             color = teal, shape = 108, size = 4, na.rm = TRUE) +
  geom_point(data = filtered_data %>% filter(male == 0), 
             aes(x = reorder(countrycode, year_2023), y = year_2023), 
             color = teal, na.rm = TRUE) +
  
  # Facet by region in rows, move labels to the left
  facet_grid(region ~ grade, scales = "free_y", space = "free_y") +
  coord_flip(clip = "off") +
  ylim(0, 1) + 
  
  # Theme modifications for left-side facet labels
  theme_minimal() +
  theme(
    strip.placement = "left",  # Move facet labels to the left
    strip.text.y = element_text(angle = 90),  # Rotate text for better readability
    panel.spacing.y = unit(0.5, "lines")  # Adjust spacing between facets
  ) + labs(y=var)

ggsave(g, filename = file.path(projectFolder, paste("/01_harmonization/",var , ".png", sep = '')),bg="white") 

}

makegraph("bullying_c_all")
makegraph("violence_c_all")
makegraph("violence_c_cp")
makegraph("violence_c_teach")
makegraph("bullying_pv")
makegraph("bullying_ev_all")
makegraph("bullying_ev_online")
makegraph("bullying_ev_trad")


transformdf <- function(df, prefix) {
  # Dynamically create column names based on the prefix
  col_25 <- paste0(prefix, "25")
  col_50 <- paste0(prefix, "50")
  col_75 <- paste0(prefix, "75")
  col_0  <- paste0(prefix, "0")  # New column to store 1 - sum

  
  newdf <- df %>%
    mutate(!!col_0 := 1 - rowSums(select(., all_of(c(col_25, col_50, col_75))), na.rm = TRUE)) %>%
    select(countrycode, year, male, grade, all_of(c(col_0, col_25, col_50, col_75))) %>%
    pivot_longer(cols = starts_with(prefix), 
                 names_to = "pct", 
                 values_to = "value") %>%
    mutate(pct = gsub(prefix, "", pct)) %>% filter(year==2023) # Remove prefix from pct values
  
  g <- ggplot(newdf %>% filter(male==-9 & year == 2023), aes(x = countrycode, y = value, fill = factor(pct))) + 
    geom_bar(stat = "identity") + 
    facet_wrap(~grade) +  # Facet by gender
    scale_fill_brewer(palette = "Blues", name = "Percentile") +  # Choose a color scale
    theme_minimal() +
    labs(title = paste0("% schools w/ X% students reporting ",prefix),
         x = "Country Code", 
         y = "Proportion",
         fill = "Percentile") +
    theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
    coord_flip(clip="off")
  
  ggsave(g, filename = file.path(projectFolder, paste("/01_harmonization/pctile_",prefix , ".png", sep = '')),bg="white") 
  
  }
transformdf(df, "bullying_ev_all")
transformdf(df, "bullying_ev_online")
transformdf(df, "bullying_ev_trad")
transformdf(df, "bullying_pv")
#prefix <- "bullying_ev_online"

### to do with scores 
# Filter and reshape the data
library(ggplot2)
library(dplyr)
library(tidyr)

create_charts <- function(var) {
  
  mf <- c(0,1)
  # Step 1: Filter dataset based on the subgroup argument
  df_filtered <- scores %>%
    filter(subgroup==paste0(var,"=0") | subgroup==paste0(var,"=1")) %>%  # Correctly filter based on `subgroup` column
    mutate(subgroup_value = ifelse(grepl("=1$", subgroup), "1", "0")) 
  
  # Step 2: Reshape the dataset to long formavarimax()# Step 2: Reshape the dataset to long format for plotting (all m_* columns)
  df_long <- df_filtered %>%
    pivot_longer(cols = starts_with("m_"), names_to = "outcome", values_to = "value")
  
  for (i in unique(mf)) {
  
  # Step 3: Generate line charts (trend from 2019-2023 for all countries)
  line_chart1 <- ggplot(df_long %>% filter(grade==4 & (outcome=="m_score_timss_math" | outcome=="m_score_timss_scie") & male == i), 
                        aes(x = year, y = value, color = factor(male), group = interaction(countrycode, male, subgroup))) +  # 
    geom_line() +
    geom_point() +
    facet_grid(outcome ~ subgroup) +  # Separate outcomes vertically, grade & male horizontally
    labs(title = paste("Trend Analysis for", var),
         x = "Year", y = "Score",
         color = "Male") +
    theme_minimal() 
  
  line_chart2 <- ggplot(df_long %>% filter(grade==4 & (outcome=="m_sdg411_math" | outcome=="m_sdg411_scie")  & male == i), 
                        aes(x = year, y = value, color = factor(male), group = interaction(countrycode, male, subgroup))) +  # 
    geom_line() +
    geom_point() +
    facet_grid(outcome ~ subgroup) +  # Separate outcomes vertically, grade & male horizontally
    labs(title = paste("Trend Analysis for", var, " male = ", i ),
         x = "Year", y = "Score",
         color = "Male") +
    theme_minimal() 
  
  
  line_chart <- ggarrange(line_chart1, line_chart2)
  ggsave(line_chart, filename = file.path(projectFolder, paste("/01_harmonization/linebar_",var ,"_",i, ".png", sep = '')),bg="white") 
  
  
  
  # Step 4: Generate bar charts (all countries, subgroup side-by-side, split by grade & male)
  chart1 <- ggplot(df_long %>% filter(grade==4 & (outcome=="m_score_timss_math" | outcome=="m_score_timss_scie") & year==2023  & male == i), aes(x = reorder(countrycode,value), y = value, fill = factor(male))) +
    geom_bar(stat = "identity", position = "dodge") +  # Dodge to make subgroups side-by-side
    facet_grid(subgroup ~ outcome, scales = "free_y", space = "free_y") +  # Separate outcomes vertically, grade & male horizontally
    labs(title = paste("Country Comparison for ", var),
         x = "Country", y = "Score",
         fill = "male") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 90, hjust = 1))  # Rotate x-axis labels for readability 
  
  chart2 <- ggplot(df_long %>% filter(grade==4 & (outcome=="m_sdg411_math" | outcome=="m_sdg411_scie")  & year==2023  & male == i), aes(x = reorder(countrycode,value), y = value, fill = factor(male))) +
    geom_bar(stat = "identity", position = "dodge") +  # Dodge to make subgroups side-by-side
    facet_grid(subgroup ~ outcome, scales = "free_y", space = "free_y") +  # Separate outcomes vertically, grade & male horizontally
    labs(title = paste("Country Comparison for ", var, " male = ", i ),
         x = "Country", y = "Score",
         fill = "male") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 90, hjust = 1))  # Rotate x-axis labels for readability 
  
  bar_chart <- ggarrange(chart1, chart2)
  ggsave(bar_chart, filename = file.path(projectFolder, paste("/01_harmonization/scoresbar_",var ,"_",i, ".png", sep = '')),bg="white", w=14) 
  }
#  print(bar_chart)  # Display the bar chart
}

create_charts("bul_pv")
create_charts("bul_c_all")
create_charts("bul_ev_all")
create_charts("bul_ev_o")
create_charts("bul_ev_trad")
