# Banned license plates generator

This R code uses Keras to train a neural network on license plates that were banned by the Arizona Department of Transportation. It was my attempt at using neural networks to make something funny like the AI trained on [band names](https://twitter.com/botnikstudios/status/955870327652970496
), [video game titles](https://disexplications.tumblr.com/post/159165060164/video-game-titles-created-by-a-neural-network), and [pokemon](http://aiweirdness.com/post/147834883707/pokemon-generated-by-neural-network).

The code is based heavily on the RStudio [text generation example](https://keras.rstudio.com/articles/examples/lstm_text_generation.html).

The license plate corpus comes from a [google search](http://www.governmentattic.org/7docs/AZ-BannedPlates_2012.pdf) and is included in the repository, however I have a Public Records Request out for more recent data from the state.

The code is broken into three files:

  1. __load_data_functions.R__ - this file has the functions that handle loading and formatting the data
  2. __model_functions.R__ - this file has the functions that make the model and generate the license plates
  3. __run_model.R__ - this script actually runs all the functions and generates a data frame of license plates
