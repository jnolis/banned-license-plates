require(readr)
require(stringr)
require(dplyr)
require(purrr)
require(tokenizers)
require(keras)

# Model functions --------------------------------------------------------

# create the model based on the number of characters and max length
create_model <- function(characters,max_length){
  #create the model using the parameters from https://keras.rstudio.com/articles/examples/lstm_text_generation.html
  keras_model_sequential() %>%
    layer_lstm(128, input_shape = c(max_length, length(characters))) %>%
    layer_dense(length(characters)) %>%
    layer_activation("softmax") %>% 
    compile(
      loss = "categorical_crossentropy", 
      optimizer = optimizer_rmsprop(lr = 0.01)
    )
}

# a function that fits the model for a set number of epochs
fit_model <- function(model,vectors, epochs = 1){
  model %>% fit(
    vectors$x, vectors$y,
    batch_size = 128,
    epochs = epochs
  )
  NULL
}

# this function iterates the model through many fits. It's really
# just a wrapper around fit model that gives lots of extra outputs.
# You could remove it and just use fit model with no problems
iterate_model <- function(model, characters, max_length, diversity, vectors, iterations){
  for(iteration in 1:iterations){
    
    cat(sprintf("iteration: %02d ---------------\n\n", iteration))
    
    fit_model(model,vectors)
    
    for(diversity in c(0.2, 0.5, 1, 1.2)){
      
      cat(sprintf("diversity: %f ---------------\n\n", diversity))
      
      current_plate <- 1:10 %>% map_chr(function(x) generate_plate(model,characters,max_length, diversity))
      
      cat(current_plate,sep="\n")
      cat("\n\n")
      
    }
  }
  NULL
}

# Plate functions --------------------------------------

# this function takes a model, the characters, and a set diversity and generates a plate
# from it. We have to use special logic to stop when we see the stop character
generate_plate <- function(model, characters, max_length, diversity){
  # this function chooses the next character for the plate. We basically call this function
  # repeatedly until we have a full plate
  choose_next_char <- function(preds, characters,temperature = 1){
    preds <- log(preds)/temperature
    exp_preds <- exp(preds)
    preds <- exp_preds/sum(exp(preds))
    
    next_index <- 
      rmultinom(1, 1, preds) %>% 
      as.integer() %>%
      which.max()
    characters[next_index]
  }
  
  #this function takes a sequence of characters and turns it into a numeric array for the model
  convert_sentence_to_data <- function(sentence, characters){
    x <- sapply(characters, function(x){
      as.integer(x == sentence)
    })
    x <- array_reshape(x, c(1, dim(x)))
    x
  }
  
  # the inital plate is just empty characters
  sentence <- rep("*",max_length)
  generated <- ""
  next_char <- ""
  
  # while we still need characters for the plate
  count <- 0
  while (count < max_length - 1 && next_char != "+"){
    count <- count + 1
    
    sentence_data <- convert_sentence_to_data(sentence,characters)
    
    # get the predictions for each next character
    preds <- predict(model, sentence_data)
    
    #choose the character
    next_char <- choose_next_char(preds, characters, diversity)
    
    # if the next character isn't a stop character, add it to the plate and continue
    if(next_char != "+"){
      generated <- str_c(generated, next_char, collapse = "")
      sentence <- c(sentence[-1], next_char)
    }
  }
  generated
}
