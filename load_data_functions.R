#this file loads the packages and creates the functions that will be used in the model
require(readr)
require(stringr)
require(dplyr)
require(purrr)
require(tokenizers)
require(keras)

# This function loads the raw text of the plates
get_plates <- function(max_length = 7) {
  read_lines("Data/Az-bannedplates_2012.txt") %>%
  str_replace_all("[^[:alnum:] ]", "") %>% # remove any special characters
  toupper() %>% # convert to upper case
  unique() %>% # remove any duplicate plates
  discard(is.na) %>% # remove any NA plates
  discard(~ .x == "") %>% # remove empty plates
  discard(~nchar(.x) > max_length) # remove plates that are too long
}

add_stop <- function(plates, symbol="+") str_c(plates,symbol) # make a note for the end of a plate

# for each plate, we want to predict each of the n character on the plate. This we have to split one
# data point (a plate) into n data points (where n is the number of characters on the plate).
# So plate ABC would become data points "A", "AB", and "ABC"
split_into_subs <- function(plates){
  plates %>%
    tokenize_characters(lowercase=FALSE) %>%
    map(~ purrr::accumulate(.x,c)) %>%
    flatten()
}

# make each data point the same number of characters by
# adding a padding symbol * to the font
fill_data <- function(plate_characters,max_length = 7){
    plate_characters %>%
    map(function(s){
      if (max_length+1  > length(s)) {
        fill <- rep("*",max_length+1-length(s))
        c(fill,s)
      } else {
        s
      }
    })
}

# convert the data into vectors that can be used by keras
vectorize <- function(data,characters,max_length){
  x <- array(0, dim = c(length(data), max_length, length(characters)))
  y <- array(0, dim = c(length(data), length(characters)))
  
  for(i in 1:length(data)){
    for(j in 1:(max_length)){
      x[i,j,which(characters==data[[i]][j])] <- 1
    }
    y[i,which(characters==data[[i]][max_length+1])] <- 1
  }
  list(y=y,x=x)
}