#!/bin/bash

# Check if a URL was provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <youtube_url>"
    exit 1
fi

# Create a directory called output
DIR="output"
mkdir -p "$DIR"

read -rp "Enter the base name of the track: " base_name

# Download audio from YouTube into the temporary folder
yt-dlp -x --audio-format "wav" "$1" -o "$DIR/$base_name.wav"

# Navigate to the temporary directory for demucs processing
cd "$DIR" || exit

ffmpeg -i "$base_name.wav" -codec:a libmp3lame -qscale:a 2 "$base_name.mp3"

# Use demucs to separate the sources
demucs --mp3 "$base_name".wav

rm "$base_name".wav

BASE_PATH="separated/htdemucs/$base_name"

# Generate version without vocals
ffmpeg -i "$BASE_PATH/bass.mp3" -i "$BASE_PATH/drums.mp3" -i "$BASE_PATH/other.mp3" -filter_complex "[0][1][2]amix=3" -codec:a libmp3lame -qscale:a 2 "(No Vocals) $base_name.mp3"

# Generate version without bass
ffmpeg -i "$BASE_PATH/drums.mp3" -i "$BASE_PATH/vocals.mp3" -i "$BASE_PATH/other.mp3" -filter_complex "[0][1][2]amix=3" -codec:a libmp3lame -qscale:a 2 "(No Bass) $base_name.mp3"

# Generate version without drums
ffmpeg -i "$BASE_PATH/bass.mp3" -i "$BASE_PATH/vocals.mp3" -i "$BASE_PATH/other.mp3" -filter_complex "[0][1][2]amix=3" -codec:a libmp3lame -qscale:a 2 "(No Drums) $base_name.mp3"


# Move all files in $BASE_PATH to $DIR
pwd
mv "$BASE_PATH"/* ./
# rm -rf "$BASE_PATH"

open .

# Ask user which instrument to transcribe
echo "Please select the instrument you want to transcribe:"
echo "1) Whole Song"
echo "2) Drums"
echo "3) Vocals"
echo "4) Bass"
echo "5) Other"
read -rp "Enter the number corresponding to your choice: " choice

case $choice in
    1)
        FILE_TO_OPEN="$base_name.mp3"
        ;;
    2)
        FILE_TO_OPEN="separated/htdemucs/downloaded_audio/drums.mp3"
        ;;
    3)
        FILE_TO_OPEN="separated/htdemucs/downloaded_audio/vocals.mp3"
        ;;
    4)
        FILE_TO_OPEN="separated/htdemucs/downloaded_audio/bass.mp3"
        ;;
    5)
        echo "Specify the instrument filename:"
        read -r instrument_file
        FILE_TO_OPEN="separated/htdemucs/downloaded_audio/$instrument_file.mp3"
        ;;
    *)
        echo "Invalid choice!"
        exit 1
        ;;
esac

# Open the chosen instrument in Transcribe
open -a Transcribe! "$FILE_TO_OPEN"
