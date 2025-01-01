#!/usr/bin/env bash

# Exit on error and undefined variables
set -euo pipefail

# Check for required commands
for cmd in ffmpeg curl jq; do
    if ! command -v $cmd &>/dev/null; then
        echo "Error: $cmd is not installed. Please install it and try again."
        exit 1
    fi
done

# Check if .env file exists and source it
if [ -f .env ]; then
    source .env
else
    echo "Error: .env file not found. Please create it with OPENAI_API_KEY and GROQ_API_KEY"
    exit 1
fi

# Check if API keys are set
if [ -z "${OPENAI_API_KEY:-}" ]; then
    echo "Error: OPENAI_API_KEY is not set in .env file"
    exit 1
fi

if [ -z "${GROQ_API_KEY:-}" ]; then
    echo "Error: GROQ_API_KEY is not set in .env file"
    exit 1
fi

# Function to preprocess audio
preprocess_audio() {
    local input_file="$1"
    local output_file="${input_file%.*}_processed.mp3"
    ffmpeg -i "$input_file" -ar 16000 -ac 1 -acodec libmp3lame -b:a 128k "$output_file" \
        -loglevel warning \
        -stats \
        2>&1 | grep -E "size=|time=" | tr '\r' '\n' | tail -n 1
    echo "$output_file"
}

# Function to transcribe audio using OpenAI
transcribe_audio_openai() {
    local audio_file="$1"
    curl -s https://api.openai.com/v1/audio/transcriptions \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -H "Content-Type: multipart/form-data" \
        -F file="@$audio_file" \
        -F language="sr" \
        -F model="whisper-1" |
        jq -r '.text'
}

# Function to transcribe audio using Groq
transcribe_audio_groq() {
    local audio_file="$1"
    curl -s https://api.groq.com/openai/v1/audio/transcriptions \
        -H "Authorization: Bearer $GROQ_API_KEY" \
        -H "Content-Type: multipart/form-data" \
        -F file="@$audio_file" \
        -F model="whisper-large-v3" \
        -F temperature=0 \
        -F response_format=json \
        -F language=sr |
        jq -r '.text'
}

# Function to clean up transcript
cleanup_transcript() {
    local transcript="$1"
    local request=$(jq -n \
        --arg model "gpt-4o" \
        --arg system "Ispravite gramaticki tekst koji je dat. Vratite iskljucivo ispravljenu verziju, bez dodatnih komentara." \
        --arg user "$transcript" \
        '{model: $model, messages: [{role: "system", content: $system}, {role: "user", content: $user}]}')

    curl -s https://api.openai.com/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -d "$request" |
        jq -r '.choices[0].message.content'
}

# Main script
if [ $# -eq 0 ]; then
    echo "Usage: $0 <path_to_audio_file> [openai|groq]"
    exit 1
fi

input_file="$1"
api_choice="${2:-groq}" # Default to Groq if not specified

if [ ! -f "$input_file" ]; then
    echo "Error: File not found: $input_file"
    exit 1
fi

echo "Preprocessing audio..."
processed_file=$(preprocess_audio "$input_file")

echo "Transcribing audio using ${api_choice^} API..."
if [ "$api_choice" = "openai" ]; then
    transcript=$(transcribe_audio_openai "$processed_file")
else
    transcript=$(transcribe_audio_groq "$processed_file")
fi

echo "Cleaning up transcript..."
cleaned_transcript=$(cleanup_transcript "$transcript")

echo -e "\nOriginal Transcript:"
echo "$transcript"

echo -e "\nCleaned Transcript:"
echo "$cleaned_transcript"

# Clean up processed file
rm "$processed_file"
