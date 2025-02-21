library(glatos)
library(sf)
library(mapview)
library(plotly)
library(gganimate)
library(ggmap)
library(tidyverse)


setwd("/YOUR/PATH/TO/data/glatos")

det_file_name <- system.file("extdata", "walleye_detections.csv",
                             package = "glatos")

detection_events <- #create detections event variable
  read_glatos_detections(det_file=det_file_name) %>%
  false_detections(tf = 3600) %>%  #find false detections
  dplyr::filter(passed_filter != FALSE) %>% 
  detection_events(location_col = 'station', time_sep=3600)

plot_data <- detection_events %>% 
  dplyr::select(animal_id, mean_longitude,mean_latitude, first_detection)

one_fish <- plot_data[plot_data$animal_id == "23",] 

ggmap::register_stadiamaps("b01d1235-69e8-49ea-b3bd-c35b42424b00")

basemap <- 
  get_stadiamap(
    bbox = c(left = min(one_fish$mean_longitude),
             bottom = min(one_fish$mean_latitude), 
             right = max(one_fish$mean_longitude), 
             top = max(one_fish$mean_latitude)),
    maptype = "stamen_toner_lite",
    crop = FALSE, 
    zoom = 7)

glatos.plot <-
  ggmap(basemap) +
  geom_point(data = one_fish, aes(x = mean_longitude, y = mean_latitude), size = 2) +
  geom_path(data = one_fish, aes(x = mean_longitude, y = mean_latitude)) +
  labs(title = "Walleye animation",
       x = "Longitude", y = "Latitude", color = "Tag ID")

ggplotly(glatos.plot)

glatos.plot <-
  glatos.plot +
  labs(subtitle = 'Date: {format(frame_along, "%d %b %Y")}') +
  transition_reveal(first_detection) +
  shadow_mark(past = TRUE, future = FALSE)

animate(glatos.plot)
