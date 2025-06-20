#This script generates a grid of thumbnails from a video at regular intervals, useful for quickly previewing video content or creating contact sheets.
#Customization: Allows control over thumbnail size, interval, and the number of images in the grid.
#Debugging/QA: Helps in quickly scanning for specific moments or issues in a video.
#Content Cataloging: Useful for creating catalogs of video files without playing each one
#Visual Overview: Provides a quick visual summary of a video's content.

#!/bin/bash

# --- Configuration ---
INPUT_FILE="$1" # First argument is the input video file
OUTPUT_DIR="$HOME/Video_Thumbnails"
THUMBNAIL_WIDTH=160 # Width of each individual thumbnail
THUMBNAIL_INTERVAL_SECONDS=10 # Take a thumbnail every X seconds
THUMBNAIL_COUNT=10 # Number of thumbnails to generate for the grid

# --- Script Logic ---
if [ -z "$INPUT_FILE" ]; then
    echo "Usage: $0 <input_video_file>"
    echo "Example: $0 my_long_video.mp4"
    exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file '$INPUT_FILE' not found."
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

BASENAME=$(basename "$INPUT_FILE")
FILENAME_NO_EXT="${BASENAME%.*}"
OUTPUT_IMAGE="${OUTPUT_DIR}/${FILENAME_NO_EXT}_thumbnails.jpg"

# Get video duration
DURATION_SECONDS=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$INPUT_FILE" | cut -d'.' -f1)

if [ -z "$DURATION_SECONDS" ] || [ "$DURATION_SECONDS" -eq 0 ]; then
    echo "Error: Could not determine video duration or duration is zero."
    exit 1
fi

echo "Generating thumbnails for: $INPUT_FILE"
echo "Duration: ${DURATION_SECONDS} seconds"
echo "Output grid to: $OUTPUT_IMAGE"

# Calculate appropriate interval for even distribution if THUMBNAIL_INTERVAL_SECONDS is too high
ACTUAL_INTERVAL=$THUMBNAIL_INTERVAL_SECONDS
if (( DURATION_SECONDS / THUMBNAIL_COUNT < THUMBNAIL_INTERVAL_SECONDS )); then
    ACTUAL_INTERVAL=$((DURATION_SECONDS / THUMBNAIL_COUNT))
    if [ "$ACTUAL_INTERVAL" -eq 0 ]; then ACTUAL_INTERVAL=1; fi # Prevent division by zero
    echo "Adjusted interval to $ACTUAL_INTERVAL seconds to get $THUMBNAIL_COUNT thumbnails evenly."
fi


# Ffmpeg command:
# -i "$INPUT_FILE" : Input video
# -vf "select=not(mod(n\,${FPS_INTERVAL})),scale=${THUMBNAIL_WIDTH}:-1" :
#   Selects frames (using 'not(mod(n\,X))' for every Xth frame, or 'select=...' for time-based)
#   Scales them to THUMBNAIL_WIDTH while maintaining aspect ratio
# -vsync vfr : Variable frame rate, ensures frames are taken at specific intervals
# -frames:v "$THUMBNAIL_COUNT" : Limit to a specific number of output frames
# -q:v 2 : Quality (2 is good, 1 is best, 31 is worst)
# -fps "${TARGET_FPS}" : Specific FPS for output
# -vframes $THUMBNAIL_COUNT : Limit output frames
# -vf "thumbnail,scale=${THUMBNAIL_WIDTH}:-1" : Simple thumbnail filter, picks a representative frame
# "-vf select='not(mod(t,${ACTUAL_INTERVAL}))',scale=${THUMBNAIL_WIDTH}:-1" : Select frames based on time interval
# -tile ${COLUMNS}x${ROWS} : Tile filter to create a grid (requires imagemagick or ffmpeg with libvpx for older versions, or combine with 'montage')

# More robust ffmpeg command for grid generation:
# Create individual thumbnails first, then use imagemagick montage or ffmpeg's tile filter
# This approach uses select filter to get frames at specific time intervals
# and then generates a contact sheet.
# The `tile` filter for ffmpeg is usually compiled in.

echo "Generating individual frames..."
TEMP_DIR=$(mktemp -d -t video_thumbs_XXXXXX)
ffmpeg -i "$INPUT_FILE" \
       -vf "select='not(mod(t,${ACTUAL_INTERVAL}))',scale=${THUMBNAIL_WIDTH}:-1" \
       -vsync vfr \
       -vframes "$THUMBNAIL_COUNT" \
       "${TEMP_DIR}/thumb_%03d.jpg"

if [ $? -ne 0 ]; then
    echo "Error generating individual thumbnails."
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Determine grid dimensions (approximate square)
SQRT_COUNT=$(echo "sqrt($THUMBNAIL_COUNT)" | bc -l | cut -d'.' -f1)
COLUMNS=$SQRT_COUNT
ROWS=$(( (THUMBNAIL_COUNT + COLUMNS - 1) / COLUMNS )) # Ceiling division

echo "Creating thumbnail grid (${COLUMNS}x${ROWS})..."
# Using ffmpeg's 'tile' filter for grid creation (more robust than imagemagick for large sets)
ffmpeg -i "${TEMP_DIR}/thumb_%03d.jpg" \
       -filter_complex "tile=${COLUMNS}x${ROWS}" \
       -frames:v 1 \
       "$OUTPUT_IMAGE"

if [ $? -eq 0 ]; then
    echo "Thumbnail grid created: $OUTPUT_IMAGE"
else
    echo "Error creating thumbnail grid."
fi

# Clean up temporary files
rm -rf "$TEMP_DIR"