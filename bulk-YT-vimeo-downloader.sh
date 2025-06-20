#This script uses yt-dlp (a superior youtube-dl fork) to download multiple videos from a list, extracting useful metadata and saving it in a structured way.

#!/bin/bash

# --- Configuration ---
VIDEO_LIST_FILE="$HOME/video_urls.txt" # A file with one URL per line
OUTPUT_DIR="$HOME/Downloaded_Videos"
FORMAT_PREFERENCE="bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best" # Prioritize MP4, then best overall

# --- Script Logic ---
mkdir -p "$OUTPUT_DIR"

if [ ! -f "$VIDEO_LIST_FILE" ]; then
    echo "Error: Video list file '$VIDEO_LIST_FILE' not found."
    echo "Create this file with one video URL per line."
    exit 1
fi

echo "Starting bulk download from '$VIDEO_LIST_FILE'..."
echo "Downloads will be saved to: $OUTPUT_DIR"

while IFS= read -r URL; do
    if [[ -z "$URL" || "$URL" =~ ^# ]]; then # Skip empty lines and comments
        continue
    fi

    echo ""
    echo "--- Processing: $URL ---"
    
    # yt-dlp command:
    # -o '%(uploader)s/%(title)s.%(ext)s' : Organizes by uploader, then title.ext
    # --embed-thumbnail : Embeds thumbnail into video file
    # --add-metadata : Adds all available metadata to the video file
    # --format "$FORMAT_PREFERENCE" : Specifies preferred video/audio formats
    # --write-info-json : Writes a JSON file with all metadata
    # --restrict-filenames : Creates safer filenames
    # --batch-file : Reads URLs from a file (though we're looping manually here for more control)

    yt-dlp \
        -o "${OUTPUT_DIR}/%(uploader)s/%(title)s.%(ext)s" \
        --embed-thumbnail \
        --add-metadata \
        --format "$FORMAT_PREFERENCE" \
        --write-info-json \
        --restrict-filenames \
        "$URL"

    if [ $? -eq 0 ]; then
        echo "Successfully downloaded/processed: $URL"
    else
        echo "Error processing: $URL"
    fi
    echo "--------------------------"

done < "$VIDEO_LIST_FILE"

echo ""
echo "Bulk download complete."