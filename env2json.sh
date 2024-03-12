#!/bin/sh
## Usage
## $> env2json [PREFIX] [REMOVE_PREFIX]
## Takes all the environment variables starting with PREFIX and convert them to JSON.
## If PREFIX is not specified - it is assumed to be 'PUBLIC_' by default. 
## If REMOVE_PREFIX is not empty - the PREFIX will be removed from the key names in JSON.
## Example:
## $> PUBLIC_API_URL=https://api.example.com env2json
##    {"PUBLIC_API_URL": "https://api.example.com"}
##
## $> PUBLIC_API_URL=https://api.example.com env2json PUBLIC_ yes
##    {"API_URL": "https://api.example.com"}

PREFIX="${1:-PUBLIC_}"
REMOVE_PREFIX=${2:-null}

env | awk -F= -v remove_prefix="$2" -v prefix="$PREFIX" '
  BEGIN { prefix_length = length(prefix) + 1 }
  /^'$PREFIX'/ {
    if (remove_prefix) {
      gsub("^" prefix, "", $1);
    }
    printf "%s\"%s\": \"%s\"", (comma ? ", " : "{ "), $1, $2;
    comma = 1
  }
  END {
    if (comma) print " }";
    else print "{}"
  }'