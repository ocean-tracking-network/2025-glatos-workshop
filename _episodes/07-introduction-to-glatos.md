---
title: Introduction to glatos Data Processing Package
teaching: 30
exercises: 0
questions:
    - "How do I load my data into glatos?"
    - "How do I filter out false detections?"
    - "How can I consolidate my detections into detection events?"
    - "How do I summarize my data?"
---

The `glatos` package is a powerful toolkit that provides a wide range of functionality for loading, processing, and visualizing your data. With it, you can gain valuable insights with quick and easy commands that condense high volumes of base R into straightforward functions, with enough versatility to meet a variety of needs.

This package was originally created to meet the needs of the Great Lakes Acoustic Telemetry Observation System (GLATOS) and use their specific data formats. However, over time, the functionality has been expanded to allow operations on OTN-formatted data as well, broadening the range of possible applications for the software. As a point of clarification, "GLATOS" (all caps acronym) refers to the organization, while `glatos` refers to the package.

Our first step is setting our working directory and importing the relevant libraries.

~~~
## Set your working directory ####

setwd("YOUR/PATH/TO/data/glatos")
library(glatos)
library(tidyverse)
library(utils)
library(lubridate)
~~~
{: .language-r}

If you are following along with the workshop in the workshop repository, there should be a folder in 'data/' containing data corresponding to your node (at time of writing, FACT, ACT, GLATOS, or MigraMar). `glatos` can function with both GLATOS and OTN Node-formatted data, but the functions are different for each. Both, however, provide a marked performance boost over base R, and both ensure that the resulting data set will be compatible with the rest of the `glatos` framework.

We'll start by importing one of the `glatos` package's built-in datasets. `glatos` comes with a few datasets that are useful for testing code on a dataset known to work with the package's functions. For this workshop, we'll continue using the walleye data that we've been working with in previous lessons. First, we'll use the  `system.file` function to build the filepath to the walleye data. This saves us having to track down the file in the `glatos` package's file structure- R can find it for us automatically.

~~~
# Get file path to example walleye data
det_file_name <- system.file("extdata", "walleye_detections.csv",
                             package = "glatos")
~~~
{:.language-r}

With our filename in hand, we'll want to use the `read_glatos_detections()` function to load our data into a dataframe. In this case, our data is formatted in the GLATOS style- if it were OTN/ACT formatted, we would want to use `read_otn_detections()` instead.

Remember: you can always check a function's documentation by typing a question mark, followed by the name of the function.

~~~
## GLATOS help files are helpful!!
?read_glatos_detections

# Save our detections file data into a dataframe called detections
detections <- read_glatos_detections(det_file=det_file_name)
~~~
{: .language-r}

Remember that we can use `head()` to inspect a few lines of our data to ensure it was loaded properly.

~~~
# View first 2 rows of output
head(detections, 2)
~~~
{: .language-r}

With our data loaded, we next want to apply a false filtering algorithm to reduce the number of false detections in our dataset. glatos uses the Pincock algorithm
to filter probable false detections based on the time lag between detections- tightly clustered detections are weighted as more likely to be true, while detections spaced out temporally will be marked as false. We can also pass the time-lag threshold as a variable to the `false_detections()` function. This lets us fine-tune our filtering to allow for greater or lesser temporal space between detections before they're flagged as false.

~~~
## Filtering False Detections ####
## ?glatos::false_detections

#Write the filtered data to a new det_filtered object
#This doesn't delete any rows, it just adds a new column that tells you whether 
#or not a detection was filtered out.

detections_filtered <- false_detections(detections, tf=3600, show_plot=TRUE)
head(detections_filtered)
nrow(detections_filtered)
~~~
{: .language-r}

The false_detections function will add a new column to your dataframe, 'passed_filter'. This contains a boolean value that will tell you whether or not that record passed the false detection filter. That information may be useful on its own merits; for now, we will just use it to filter out the false detections.

~~~
# Filter based on the column if you're happy with it.

detections_filtered <- detections_filtered[detections_filtered$passed_filter == 1,]
nrow(detections_filtered) # Smaller than before
~~~
{: .language-r}

With our data properly filtered, we can begin investigating it and developing some insights. `glatos` provides a range of tools for summarizing our data so that we can better see what our receivers are telling us.

We can begin with a summary by animal, which will group our data by the unique animals we've detected.

~~~
# Summarize Detections ####
#?summarize_detections
#summarize_detections(detections_filtered)

# By animal ====
sum_animal <- summarize_detections(detections_filtered, location_col = 'station', summ_type='animal')

sum_animal
~~~
{: .language-r}

We can also summarize by location, grouping our data by distinct locations.

~~~
# By location ====

sum_location <- summarize_detections(detections_filtered, location_col = 'station', summ_type='location')

head(sum_location)
~~~
{: .language-r}

`summarize_detections` will return different summaries depending on the summ_type parameter. It can take either "animal", "location", or "both". More information on what these summaries return and how they are structured can be found in the help files (?summarize_detections).

If you had another column that describes the location of a detection, and you would prefer to use that, you can specify it in the function with the `location_col` parameter. In the example below, we will create a new column and use that as the location.

~~~
# You can make your own column and use that as the location_col
# For example we will create a uniq_station column for if you have duplicate station names across projects

detections_filtered_special <- detections_filtered %>%
  mutate(station_uniq = paste(glatos_project_receiver, station, sep=':'))

sum_location_special <- summarize_detections(detections_filtered_special, location_col = 'station_uniq', summ_type='location')

head(sum_location_special)
~~~
{: .language-r}

For the next example, we'll summarise along both animal and location, as outlined above.
~~~
# By both dimensions
sum_animal_location <- summarize_detections(det = detections_filtered,
                                            location_col = 'station',
                                            summ_type='both')

head(sum_animal_location)
~~~
{: .language-r}

Summarising by both dimensions will create a row for each station and each animal pair. This can be a bit cluttered, so let's use a filter to remove every row where the animal was not detected on the corresponding station.
~~~
# Filter out stations where the animal was NOT detected.

sum_animal_location <- sum_animal_location %>% filter(num_dets > 0)

sum_animal_location
~~~
{: .language-r}

One other method we can use is to summarize by a subset of our animals as well. If we only want to see summary data for a fixed set of animals, we can pass an array containing the animal_ids that we want to see summarized.

~~~
# create a custom vector of Animal IDs to pass to the summary function
# look only for these ids when doing your summary
tagged_fish <- c('22', '23')

sum_animal_custom <- summarize_detections(det=detections_filtered,
                                          animals=tagged_fish,  # Supply the vector to the function
                                          location_col = 'station',
                                          summ_type='animal')

sum_animal_custom
~~~
{: .language-r}

Now that we have an overview of how to quickly and elegantly summarize our data, let's make our dataset more amenable to plotting by reducing it from detections to detection events.

Detection Events differ from detections in that they condense a lot of temporally and spatially clustered detections for a single animal into a single detection event. This is a powerful and useful way to clean up the data, and makes it easier to present and clearer to read. Fortunately, this is easy to do with `glatos`.

~~~
# Reduce Detections to Detection Events ####

# ?glatos::detection_events
# you specify how long an animal must be absent before starting a fresh event

events <- detection_events(detections_filtered,
                           location_col = 'station',
                           time_sep=3600)

head(events)
~~~
{: .language-r}

`location_col` tells the function what to use as the locations by which to group the data, while `time_sep` tells it how much time has to elapse between sequential detections before the detection belongs to a new event (in this case, 3600 seconds, or an hour). The threshold for your data may be different depending on the purpose of your project.

We can also keep the full extent of our detections, but add a group column so that we can see how they
would have been condensed.

~~~
# keep detections, but add a 'group' column for each event group

detections_w_events <- detection_events(detections_filtered,
                                        location_col = 'station',
                                        time_sep=3600, condense=FALSE)
~~~
{: .language-r}

With our filtered data in hand, let's move on to some visualization.