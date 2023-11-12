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

# Function to generate and perform commit asynchronously
generate_and_commit() {
    # Capture git diff of staged files
    git_diff=$(git diff --cached)

    # If there are no staged changes, exit the function
    if [ -z "$git_diff" ]; then
        echo "No staged changes to commit."
        return
    fi

    # Prepare the payload with the git diff
    payload=$(jq -n \
                  --arg diff "$git_diff" \
                  '{model: "gpt-3.5-turbo", messages: [{role: "system", content: "You are an assistant who generates commit messages based on git diffs of staged changes."}, {role: "user", content: $diff}]}')

    # Call the OpenAI API
    response=$(curl -s https://api.openai.com/v1/chat/completions \
                    -H "Content-Type: application/json" \
                    -H "Authorization: Bearer $OPENAI_API_KEY" \
                    -d "$payload")

    echo $response

    # Extract the commit message from the response
    commit_message=$(echo "$response" | jq -r '.choices[0].message.content')

    one_line_commit_message=$(echo "$commit_message" | tr '\n' ' ')

    # Commit the changes with the generated message
    if [ -n "$one_line_commit_message" ]; then
        git commit -m "AI Generated Message: $one_line_commit_message"
        echo "Committed with AI-generated message: $one_line_commit_message"
    fi
}

# Main script execution
# Get the current working directory
current_path=$(git rev-parse --show-toplevel)

# Check if the current path is not a subdirectory of the Projects directory
if ! is_subdir $work_path $current_path; then
    # Call generate_and_commit in the background
    generate_and_commit &
fi
