#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

echo "Enter your username:"
read USERNAME

# Check if the username exists
USER_INFO=$($PSQL "SELECT user_id, games_played, best_game FROM users WHERE username = '$USERNAME'")

if [[ -z $USER_INFO ]]; then
  # New user
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  # Insert the new user into the database
  INSERT_USER_RESULT=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME')")
else
  # Existing user
  echo "$USER_INFO" | while IFS='|' read USER_ID GAMES_PLAYED BEST_GAME; do
    echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
  done
fi

# Generate the secret number
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
echo "Guess the secret number between 1 and 1000:"
NUMBER_OF_GUESSES=0

while true; do
  read GUESS
  ((NUMBER_OF_GUESSES++))

  # Check if the input is an integer
  if ! [[ $GUESS =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi

  # Compare the guess with the secret number
  if [[ $GUESS -lt $SECRET_NUMBER ]]; then
    echo "It's higher than that, guess again:"
  elif [[ $GUESS -gt $SECRET_NUMBER ]]; then
    echo "It's lower than that, guess again:"
  else
    echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
    break
  fi
done

# Update the user's information in the database
if [[ -z $USER_INFO ]]; then
  # New user
  UPDATE_RESULT=$($PSQL "UPDATE users SET games_played = 1, best_game = $NUMBER_OF_GUESSES WHERE username = '$USERNAME'")
else
  echo "$USER_INFO" | while IFS='|' read USER_ID GAMES_PLAYED BEST_GAME; do
    # Update games played and best game if necessary
    NEW_GAMES_PLAYED=$((GAMES_PLAYED + 1))
    if [[ -z $BEST_GAME || $NUMBER_OF_GUESSES -lt $BEST_GAME ]]; then
      BEST_GAME=$NUMBER_OF_GUESSES
    fi
    UPDATE_RESULT=$($PSQL "UPDATE users SET games_played = $NEW_GAMES_PLAYED, best_game = $BEST_GAME WHERE user_id = $USER_ID")
  done
fi
