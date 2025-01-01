#!/usr/bin/env bash

# Execute script from the directory where it is located
cd "$(dirname "$0")" || exit

source bash-helpers.sh

exit_on_error_and_undefined

install_if_not_installed curl jq

# Install xclip if on Linux
if [[ "$(uname -s)" != "Darwin" ]]; then
    install_if_not_installed xclip
fi

# Source environment variables
source .env

# Check if OPENAI_API_KEY is set
if [ -z "$OPENAI_API_KEY" ]; then
    echo "Error: OPENAI_API_KEY is not set in .env file"
    sleep 7
    exit 1
fi

# Global variables for cleanup
IMAGE_URL=""
TOKEN=""
TEMP_IMAGE=""

# Generate random filename
generate_temp_filename() {
    local timestamp=$(date +%s)
    local random_string=$(head /dev/urandom | tr -dc 'a-z0-9' | head -c 6)
    echo "image-${timestamp}-${random_string}.png"
}

# Function to cleanup uploaded image
cleanup() {
    if [ -n "$TOKEN" ] && [ -n "$IMAGE_URL" ]; then
        info "Cleaning up uploaded image..."
        curl -s -F "token=$TOKEN" -F "delete=" "$IMAGE_URL" >/dev/null
    fi
    [ -n "$TEMP_IMAGE" ] && rm -f "$TEMP_IMAGE"
}

# Set cleanup trap
trap cleanup EXIT

# Function to get image from clipboard and save it
get_image_from_clipboard() {
    TEMP_IMAGE=$(generate_temp_filename)
    if ! copy_image_from_clipboard "$TEMP_IMAGE"; then
        echo "Error: Failed to get image from clipboard"
        sleep 7
        exit 1
    fi
    info "Image saved from clipboard as $TEMP_IMAGE"
}

# Function to upload image to 0x0.st
upload_image() {
    local response
    response=$(curl -si -F "file=@$TEMP_IMAGE" https://0x0.st)
    if [ $? -ne 0 ]; then
        echo "Error: Failed to upload image"
        sleep 7
        exit 1
    fi

    # Extract URL and token from response
    IMAGE_URL=$(echo "$response" | grep -i "^location:" | awk '{print $2}' | tr -d '\r')
    TOKEN=$(echo "$response" | grep -i "^x-token:" | awk '{print $2}' | tr -d '\r')

    if [ -z "$IMAGE_URL" ]; then
        echo "Error: Failed to get image URL from response"
        sleep 7
        exit 1
    fi

    info "Image uploaded successfully"
}

# Function to call OpenAI API with image URL
process_image_with_openai() {
    local request=$(
        cat <<EOF
{
    "model": "gpt-4o",
    "messages": [
        {
            "role": "user",
            "content": [
                {
                    "type": "text",
                    "text": "Please OCR the content of this image and return it as a YAML structure of appropriate format. Do not wrap it as markdown code block, just return the correct YAML structure."
                },
                {
                    "type": "image_url",
                    "image_url": {
                        "url": "$IMAGE_URL"
                    }
                }
            ]
        }
    ],
    "max_tokens": 1200
}
EOF
    )

    info "Calling OpenAI API to process image. Please wait..."
    response=$(curl -s https://api.openai.com/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -d "$request")

    if [ $? -ne 0 ]; then
        echo "Error: curl command failed"
        sleep 7
        exit 1
    fi

    message=$(echo "$response" | jq -r '.choices[0].message.content')
    if [ $? -ne 0 ]; then
        echo "Error: jq parsing failed"
        echo "$response"
        sleep 7
        exit 1
    fi

    echo "$message" | copy_to_clipboard

    info "OCR result copied to clipboard"
    echo -e "\n$message\n"
}

# Main execution
get_image_from_clipboard
upload_image
process_image_with_openai

echo -e "\n\n"
countdownWithNotice 15 "Window will automatically close"
