character_lookup <- data.frame(character = c(LETTERS,0:9," ","+"), stringsAsFactors = FALSE)
character_lookup[["character_id"]] <- 1:nrow(character_lookup)

num_characters <- nrow(character_lookup) + 1

max_length <- 7
