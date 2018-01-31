# code that actually runs all the functions
require(readr)
require(stringr)
require(dplyr)
require(purrr)
require(tokenizers)
require(keras)

source("load_data_functions.R")
source("model_functions.R")

# Set the max length of the plates
max_length <- 7

# get the plates from the database
plates <- get_plates(max_length)

# format the plates into the appropriate datapoints
data <-
  plates %>%
  add_stop() %>%
  split_into_subs() %>%
  fill_data(max_length = max_length)

# create the vector of characters in the data
characters <- 
  data %>% 
  flatten() %>% 
  unlist() %>% 
  unique() %>% 
  sort()

# make the vector/3D-array as the y and x data for keras
vectors <- vectorize(data, characters, max_length)

# initialize the model
model <- create_model(characters, max_length)

# iterate the model
iterate_model(model, characters, max_length, diversity, vectors, 40)

# create the result
result <- 
  runif(250,0.2,0.8) %>% #randomly choose diversity for each plate
  map_chr(~ generate_plate(model, characters, max_length, .x)) %>%
  data_frame(plate = .) %>%
  distinct %>%
  filter(!is.na(plate), plate != "") %>%
  anti_join(data_frame(plate = plates),by="plate") # remove plates that are already actual banned plates