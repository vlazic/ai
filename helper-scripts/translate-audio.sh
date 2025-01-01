#!/usr/bin/env bash

# execute script from directory where it is located
cd "$(dirname "$0")" || exit

source bash-helpers.sh

exit_on_error_and_undefined

install_if_not_installed curl ffmpeg jq

# Install xclip if on Linux
if [[ "$(uname -s)" != "Darwin" ]]; then
    install_if_not_installed xclip
fi

source .env

translation_model="gpt-4o"
# translation_model="gpt-4-turbo"
# translation_model="gpt-3.5-turbo"

# there are some predefined prompts for translation. put them in key-value array
declare -A system_messages
system_messages["serbian_fix"]="Ispravite gramaticki tekst koji je dat. Vratite iskljucivo ispravljenu verziju, bez dodatnih komentara."
system_messages["serbian_fix2"]="Molimo Vas da preoblikujete prosledjeni tekst da biste sve učinili jasnijim i razumljivijim."
# "A text in Serbian has been provided. Feel free to reinterpret it to make everything clearer and more understandable. Send it back then send --- and then send your translation."
system_messages["serbian_to_english_both"]="Translate text into English. Do not add any extra text, just translate. Feel free to reinterpret to make everything clearer as would typical native speaker say. Expected output: [[Serbian fixed text]][[newline]]---[[newline]][[English translation]]"
system_messages["serbian_to_english_both_fix"]="First fix serbian input into meaningful and coherent message, then translate fixed text into English. Feel free to reinterpret to make everything clearer. Expected output: [[Serbian fixed text]][[newline]]---[[newline]][[English translation]]"
system_messages["serbian_to_english_fix"]="Please translate the following text into English. Feel free to reinterpret to make everything clearer."
system_messages["serbian_to_english"]="Please translate the following text into English"
system_messages["serbian_to_german"]="Bitte übersetzen Sie den folgenden Text ins Deutsche. Fühlen Sie sich frei, ihn umzugestalten, um alles klarer und verständlicher zu machen."
system_messages["serbian_to_french"]="Veuillez traduire le texte suivant en français. N'hésitez pas à le réinterpréter pour que tout soit plus clair et plus compréhensible."
system_messages["serbian_to_italian"]="Si prega di tradurre il seguente testo in italiano. Sentiti libero di reinterpretarlo per rendere tutto più chiaro e comprensibile."
system_messages["serbian_to_spanish"]="Por favor, traduzca el siguiente texto al español. Siéntase libre de reinterpretarlo para que todo sea más claro y comprensible."
system_messages["serbian_to_russian"]="Пожалуйста, переведите следующий текст на русский язык. Не стесняйтесь переосмысливать его, чтобы все было более понятно и понятно."
system_messages["croatian_to_english"]="Please translate the following text into English"
system_messages["question"]="Plase answer the following question"

# if first argument is provided, check system_messages array for it
# if it is not found, use default message: system_messages["serbian_to_english"]
if [ -n "$1" ]; then
    system_message=${system_messages[$1]}
    if [ -z "$system_message" ]; then
        system_message=${system_messages["serbian_to_english"]}
    fi
else
    system_message=${system_messages["serbian_to_english"]}
fi

function check_api_key {
    local api_key
    api_key="$1"
    local key_name
    key_name="$2"

    if [ -z "$api_key" ]; then
        error "Please set $key_name in .env file"
        exit 1
    fi
}

function remove_old_audio {
    info Remove old audio file
    trap "rm -f audio.mp3 audio_processed.mp3" EXIT
}

function record_audio {
    info Record audio from microphone until ctrl+c is pressed
    if [[ "$(uname -s)" == "Darwin" ]]; then
        ffmpeg -hide_banner -loglevel error -f avfoundation -i ":0" audio.mp3
    else
        ffmpeg -hide_banner -loglevel error -f alsa -i default audio.mp3
    fi
}

function preprocess_audio {
    info Preprocessing audio for transcription
    ffmpeg -i audio.mp3 -ar 16000 -ac 1 -map 0:a audio_processed.mp3 -loglevel error
}

function transcribe_audio_openai {
    local openai_api_key
    openai_api_key="$1"

    local response
    response=$(curl -s https://api.openai.com/v1/audio/transcriptions \
        -H "Authorization: Bearer $openai_api_key" \
        -H "Content-Type: multipart/form-data" \
        -F file="@audio_processed.mp3" \
        -F language="sr" \
        -F model="whisper-1")

    local transcription
    transcription=$(echo "$response" | jq -r '.text')
    echo "$transcription"
}

function transcribe_audio_groq {
    local groq_api_key
    groq_api_key="$1"

    local response
    response=$(curl -s https://api.groq.com/openai/v1/audio/transcriptions \
        -H "Authorization: Bearer $groq_api_key" \
        -F "file=@audio_processed.mp3" \
        -F model=whisper-large-v3 \
        -F temperature=0 \
        -F response_format=json \
        -F language=sr)

    local transcription
    transcription=$(echo "$response" | jq -r '.text')
    echo "$transcription"
}

function create_translation {
    local translation_model
    translation_model="$1"
    local openai_api_key
    openai_api_key="$2"
    local system_message
    system_message="$3"
    local user_message
    user_message="$4"

    local request
    request=$(jq -n \
        --arg model "$translation_model" \
        --arg system "$system_message" \
        --arg user "$user_message" \
        '{model: $model, messages: [{role: "system", content: $system}, {role: "user", content: $user}]}')

    info "Calling OpenAI API to create translation (${system_message}). Please wait..."
    # copy output to clipboard
    response=$(curl -s https://api.openai.com/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $openai_api_key" \
        -d "$request")
    if [ $? -ne 0 ]; then
        echo "Error: curl command failed"
        exit 1
    fi

    message=$(echo "$response" | jq -r '.choices[0].message.content')
    if [ $? -ne 0 ]; then
        echo "Error: jq parsing failed"
        echo "$response"
        exit 1
    fi

    echo "$message" | copy_to_clipboard

    echo -e "\n\n------------------------------------------------------------\n${message}\n------------------------------------------------------------\n\n" >>/tmp/translate-audio.log
    echo "$message"
}

# main script execution starts here
check_api_key "$OPENAI_API_KEY" "OPENAI_API_KEY"
check_api_key "$GROQ_API_KEY" "GROQ_API_KEY"

remove_old_audio

record_audio

preprocess_audio

info Call Groq API to transcribe audio. Please wait...
transcription=$(transcribe_audio_groq "$GROQ_API_KEY")
info Transcription
echo "$transcription"
echo "\n\n------------------------------------------------------------\n${transcription}\n------------------------------------------------------------\n\n" >>/tmp/translate-audio.log

create_translation "$translation_model" "$OPENAI_API_KEY" "$system_message" "$transcription"

echo -e "\n\n"
countdownWithNotice 15 "Window will automatically close"
