#!/bin/bash

echo "The $SEASON season is more than expected, this time."

# $? is the exit status of the last command executed.
if [ $? -eq 0 ]; then
    echo "The script executed successfully."
else
    echo "There was an error executing the script."
fi

$RANDOM