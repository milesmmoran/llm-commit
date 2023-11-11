#!/bin/zsh

# Base path for projects
work_path="/Users/milesmoran/Projects"

# Function to check if the current path is a subdirectory of projects_path
is_subdir() {
    local parent_dir=$1
    local child_dir=$2

    if [[ $child_dir =~ ^$parent_dir ]]; then
        return 0 # True, it is a subdir
    else
        return 1 # False, it is not a subdir
    fi
}

# Get the current working directory
current_path=$(git rev-parse --show-toplevel)

# Check if the current path is not a subdirectory of the Projects directory
if ! is_subdir $work_path $current_path; then
    # Amend commit with "hi" for directories outside /Users/milesmoran/Projects/
    git commit -m "hi"
fi
