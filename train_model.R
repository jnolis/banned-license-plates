# MODEL TRAINING SETUP --------------------

# load the necessary libraries
library(dplyr)
library(readr)
library(stringr)
library(purrr)
library(tidyr)
library(keras) # use install_keras() if running for the first time. See https://keras.rstudio.com/ for details

# load all of the parameters. They are stored in a separate file so they can be used when
# running the model too
source("parameters.R")


# load the data. Also clean the plates as much as possible.
plate_data <- 
  read_lines("Data/Az-bannedplates_2012.txt") %>%
  str_replace_all("[^[:alnum:] ]", "") %>% # remove any special characters
  toupper() %>% # convert to upper case
  unique() %>% # remove any duplicate plates
  discard(is.na) %>% # remove any NA plates
  discard(~ .x == "") %>% # remove empty plates
  discard(~nchar(.x) > max_length) %>% # remove plates that are too long
  tibble(plate=.) %>%
  mutate(id = row_number())


# modify the data so it's ready for a model
# first we add a character to signify the end of the name ("+")
# then we need to expand each name into subsequences (F, FU, FUC) so we can predict each next character.
# finally we make them sequences of the same length. So they can form a matrix

# the subsequence data
subsequence_data <-
  plate_data %>%
  mutate(accumulated_plate =
           plate %>%
           str_c("+") %>% # add a stop character
           str_split("") %>% # split into characters
           map( ~ purrr::accumulate(.x,c)) # make into cumulative sequences
  ) %>%
  select(accumulated_plate) %>% # get only the column with the names
  unnest(accumulated_plate) %>% # break the cumulations into individual rows
  arrange(runif(n())) %>% # shuffle for good measure
  pull(accumulated_plate) # change to a list

# the name data as a matrix. This will then have the last character split off to be the y data
# this is nowhere near the fastest code that does what we need to, but it's easy to read so who cares?
text_matrix <-
  subsequence_data %>%
  map(~ character_lookup$character_id[match(.x,character_lookup$character)]) %>% # change characters into the right numbers
  pad_sequences(maxlen = max_length+1) %>% # add padding so all of the sequences have the same length
  to_categorical(num_classes = num_characters) # 1-hot encode them (so like make 2 into [0,1,0,...,0])

X <- text_matrix[,1:max_length,] # make the X data of the letters before
y <- text_matrix[,max_length+1,] # make the Y data of the next letter


# CREATING THE MODEL ---------------

# the input to the network
input <- layer_input(shape = c(max_length,num_characters)) 

# the name data needs to be processed using an LSTM, 
# Check out Deep Learning with R (Chollet & Allaire, 2018) to learn more.
# if we were using words instead of characters, or we had 10x the datapoints,
# we'd want to use more lstm layers instead of just two
output <- 
  input %>%
  layer_lstm(units = 128) %>%
  layer_dense(num_characters) %>%
  layer_activation("softmax")

# the actual model, compiled
model <- keras_model(inputs = input, outputs = output) %>% 
  compile(
    loss = 'categorical_crossentropy',
    optimizer = "adam"
  )


# RUNNING THE MODEL ----------------

# here we run the model through the data 25 times. 
# In theory the more runs the better the results, but the returns diminish
fit_results <- model %>% keras::fit(
  X, 
  y,
  batch_size = 64,
  epochs = 25
)

# SAVE THE MODEL ---------------

# save the model so that it can be used in the future
save_model_hdf5(model,"model.h5")
