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

# Function to generate commit message
generate_commit_message() {
    # Capture git diff
    git_diff=$(git diff)

    # Prepare the payload with the git diff
    payload=$(jq -n \
                  --arg diff "$git_diff" \
                  '{model: "gpt-3.5-turbo", messages: [{role: "system", content: "You are an assistant who generates commit messages based on git diffs."}, {role: "user", content: $diff}]}')

    # Call the OpenAI API
    response=$(curl https://api.openai.com/v1/chat/completions \
                    -H "Content-Type: application/json" \
                    -H "Authorization: Bearer $OPENAI_API_KEY" \
                    -d "$payload")

    # Extract the commit message from the response
    commit_message=$(echo "$response" | jq -r '.choices[0].message.content')

    # Use the commit message
    echo "$commit_message"
}

# Main script execution
# Get the current working directory
current_path=$(git rev-parse --show-toplevel)

# Check if the current path is not a subdirectory of the Projects directory
if ! is_subdir $work_path $current_path; then
    # Call generate_commit_message and use its output
    commit_msg="AI Generated: $(generate_commit_message)"
    echo "$commit_msg"
fi
