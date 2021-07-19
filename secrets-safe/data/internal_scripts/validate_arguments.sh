#!/bin/bash

#
# A helper script for validating arguments. 
# Ensures that every entry in the variable 'ARGUMENTS' is contained within 'ALLOWED_ARGUMENTS'. 
# Ensures that every argument in the variable 'REQUIRED_ARGUMENTS' is contained within 'ARGUMENTS'. 
# The 'SELECTED_FUNCTION' environment variable will be read out if an error is present. 
#

IFS=' ' read -r -a ARGUMENT <<< ${ARGUMENTS}
IFS=' ' read -r -a ALLOWED_ARGUMENT <<< ${ALLOWED_ARGUMENTS}
IFS=' ' read -r -a REQUIRED_ARGUMENT <<< ${REQUIRED_ARGUMENTS}

# Verify all arguments are allowed
for ARG in ${ARGUMENTS[@]}; do
  if [[ $ALLOWED_ARGUMENTS != *"$ARG"* ]]; then
    echo "$ARG is not an allowed argument for the $SELECTED_FUNCTION function."
    exit 1
  fi
done

# Verify all required arguments are present
for ARG in ${REQUIRED_ARGUMENTS[@]}; do
  if [[ $ARGUMENTS != *"$ARG"* ]]; then
    echo "$ARG is a required argument for the $SELECTED_FUNCTION function."
    exit 1
  fi
done
