#!/bin/zsh

# Base path for projects
work_path="/Users/milesmoran/Projects"

# Function to check if the current path is a subdirectory of projects_path
is_subdir() {
    local parent_dir=$1
    local child_dir=$2

    if [[ $child_dir =~ ^$parent_dir ]]; then
        echo "Directory $child_dir is a subdir of $parent_dir"
        return 0 # True, it is a subdir
    else
        echo "Directory $child_dir is not a subdir of $parent_dir"
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

    echo "Staged git diff: $git_diff"

    # Prepare the payload with the git diff
    payload=$(jq -n \
                  --arg diff "$git_diff" \
                  '{model: "gpt-3.5-turbo", messages: [{role: "system", content: "You are an assistant who generates commit messages based on git diffs of staged changes."}, {role: "user", content: $diff}]}')

    echo "Payload for OpenAI API: $payload"

    # Call the OpenAI API
    response=$(curl -s https://api.openai.com/v1/chat/completions \
                    -H "Content-Type: application/json" \
                    -H "Authorization: Bearer $OPENAI_API_KEY" \
                    -d "$payload")

    echo "Response from OpenAI API: $response"

    # Extract the commit message from the response
    commit_message=$(echo "$response" | jq -r '.choices[0].message.content')
    echo "Extracted commit message: $commit_message"

    # Escape newlines and control characters in the commit message
    escaped_commit_message=$(echo "$commit_message" | jq -aRs .)
    echo "Escaped commit message: $escaped_commit_message"

    # Commit the changes with the generated message
    if [ -n "$commit_message" ]; then
        echo "Committing with message: $escaped_commit_message"
        git commit -m "AI Generated Message: $escaped_commit_message"
    fi
}

# Main script execution
# Get the current working directory
current_path=$(git rev-parse --show-toplevel)
echo "Current working directory: $current_path"

# Check if the current path is not a subdirectory of the Projects directory
if ! is_subdir $work_path $current_path; then
    echo "Current path is not a subdirectory of $work_path. Generating and performing commit."
    # Call generate_and_commit in the background
    generate_and_commit &
else
    echo "Current path is a subdirectory of $work_path. No action taken."
fi
