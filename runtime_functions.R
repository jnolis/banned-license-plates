library(keras)

# load the parameters
source("parameters.R")

# load the neural network model
model <- load_model_hdf5("model.h5")


# a function that generates a single result from the model
generate_result <- function(model, character_lookup, max_length, temperature=1){
  # model - the trained neural network
  # character_lookup - the table for how characters convert to numbers
  # max_length - the expected length of the training data in characters
  # temperature - how weird to make the names, higher is weirder
  
  # given the probabilities returned from the model, this code
  choose_next_char <- function(preds, character_lookup,temperature = 1){
    preds <- log(preds)/temperature
    exp_preds <- exp(preds)
    preds <- exp_preds/sum(exp(preds))
    
    next_index <- which.max(as.integer(rmultinom(1, 1, preds)))
    character_lookup$character[next_index-1]
  }
  
  in_progress_letters <- character(0)
  next_letter <- ""
  
  # while we haven't hit a stop character and the name isn't too long
  while(next_letter != "+" && length(in_progress_letters) < 30){
    # prep the data to run in the model again
    previous_letters_data <- 
      lapply(list(in_progress_letters), function(.x){
        character_lookup$character_id[match(.x,character_lookup$character)]
      })
    previous_letters_data <- pad_sequences(previous_letters_data, maxlen = max_length)
    previous_letters_data <- to_categorical(previous_letters_data, num_classes = num_characters)
    
    # get the probabilities of each possible next character by running the model
    next_letter_probabilities <- 
      predict(model,previous_letters_data)
    
    # determine what the actual letter is
    next_letter <- choose_next_char(next_letter_probabilities,character_lookup,temperature)
    
    if(next_letter != "+")
      # if the next character isn't stop add the latest generated character to the name and continue
      in_progress_letters <- c(in_progress_letters,next_letter)
  }
  
  # turn the list of characters into a single string
  result <- paste0(in_progress_letters, collapse="")
  result
}

# a function to generate many results
generate_many_results <- function(n=10, ...){
  # n - the number of results to generate
  # (then everything else you'd pass to generate_name)
  unlist(lapply(1:n,function(x) generate_result(...)))
}
