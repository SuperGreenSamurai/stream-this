#This script converts a video file into a web-friendly format (e.g., H.264 MP4 with AAC audio) suitable for streaming, reducing file size and ensuring compatibility.

#!/bin/bash

# --- Configuration ---
INPUT_FILE="$1" # First argument is the input video file
OUTPUT_DIR="$HOME/Optimized_Videos"
TARGET_BITRATE="2M" # Target video bitrate (e.g., 2 Mbps). Adjust as needed.
AUDIO_BITRATE="128k" # Target audio bitrate (e.g., 128 kbps).
CODEC_VIDEO="libx264" # H.264 codec
CODEC_AUDIO="aac"     # AAC audio codec
PIXEL_FORMAT="yuv420p" # Ensures compatibility with most players

# --- Script Logic ---
if [ -z "$INPUT_FILE" ]; then
    echo "Usage: $0 <input_video_file>"
    echo "Example: $0 my_raw_video.mov"
    exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file '$INPUT_FILE' not found."
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

BASENAME=$(basename "$INPUT_FILE")
FILENAME_NO_EXT="${BASENAME%.*}"
OUTPUT_FILE="${OUTPUT_DIR}/${FILENAME_NO_EXT}_optimized.mp4"

echo "Optimizing video: $INPUT_FILE"
echo "Output will be saved to: $OUTPUT_FILE"

ffmpeg -i "$INPUT_FILE" \
       -c:v "$CODEC_VIDEO" -b:v "$TARGET_BITRATE" \
       -c:a "$CODEC_AUDIO" -b:a "$AUDIO_BITRATE" \
       -pix_fmt "$PIXEL_FORMAT" \
       -movflags +faststart \
       "$OUTPUT_FILE"

if [ $? -eq 0 ]; then
    echo "Video optimization complete: $OUTPUT_FILE"
else
    echo "Error during video optimization."
    rm -f "$OUTPUT_FILE" # Clean up partial file
fi