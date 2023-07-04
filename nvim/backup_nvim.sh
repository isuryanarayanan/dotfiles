#!/bin/bash

nvim_directory="$HOME/.config/nvim"
echo $HOME

if [ -d "$nvim_directory" ]; then
  cp -r "$nvim_directory" "$(dirname "$0")"/nvim
else
  echo "Error: $nvim_directory does not exist."
fi

