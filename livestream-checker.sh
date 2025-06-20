#This script monitors a live stream URL and starts recording it when it detects the stream is active. It's great for recording intermittent live events
#!/bin/bash

# --- Configuration ---
STREAM_URL="https://example.com/live/stream.m3u8" # Replace with your stream URL (e.g., HLS .m3u8, RTMP)
OUTPUT_DIR="$HOME/Recordings"
CHECK_INTERVAL_SECONDS=60 # How often to check for the stream
MAX_CHECKS_BEFORE_EXIT=1440 # Roughly 24 hours of checks (1440 * 60s = 86400s)

# --- Script Logic ---
mkdir -p "$OUTPUT_DIR"
echo "Monitoring stream: $STREAM_URL"
echo "Recordings will be saved to: $OUTPUT_DIR"
echo "Press Ctrl+C to stop monitoring."

CHECK_COUNT=0
while true; do
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    OUTPUT_FILE="${OUTPUT_DIR}/stream_recording_${TIMESTAMP}.mp4"

    echo "[$(date)] Checking for stream..."
    # A simple check: if ffmpeg can connect to the stream without error
    # You might need a more robust check depending on the stream type (e.g., curl for HTTP status)
    ffmpeg -i "$STREAM_URL" -t 5 -f null - 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "[$(date)] Stream detected! Starting recording to $OUTPUT_FILE"
        ffmpeg -i "$STREAM_URL" -c copy "$OUTPUT_FILE"
        # If ffmpeg exits, it means the stream likely ended or errored.
        # We'll continue monitoring for its return.
        echo "[$(date)] Recording stopped or stream ended. Resuming monitoring."
    else
        echo "[$(date)] Stream not active. Waiting ${CHECK_INTERVAL_SECONDS} seconds..."
    fi

    CHECK_COUNT=$((CHECK_COUNT + 1))
    if [ "$CHECK_COUNT" -ge "$MAX_CHECKS_BEFORE_EXIT" ]; then
        echo "[$(date)] Max checks reached. Exiting."
        exit 0
    fi

    sleep "$CHECK_INTERVAL_SECONDS"
done