#!/usr/bin/env sh

# Fetch current song information from rmpc
SONG_INFO=$(rmpc song)

# Extract artist, title, and file path using jq
ARTIST=$(echo "$SONG_INFO" | jq -r '.metadata.artist // empty')
TITLE=$(echo "$SONG_INFO" | jq -r 'metadata.title // empty')
FILE_PATH=$(echo "$SONG_INFO" | jq -r '.file // empty')

# Exit if artist, title, or file path metadata is missing
# if [ -z "$ARTIST" ] || [ -z "$TITLE" ] || [ -z "$FILE_PATH" ]; then
#   echo "Missing song metadata, skipping lyrics fetch."
#   exit 1
# fi

# Generate the LRC path based on the music file name
BASE_NAME=$(basename "$FILE_PATH" | sed 's/\.[^.]*$//') # Remove extension
LRC_PATH="$HOME/Music/Music/$BASE_NAME.lrc"

# Check if LRC file already exists
if [ ! -f "$LRC_PATH" ]; then
  echo "Fetching lyrics for $TITLE by $ARTIST..."
  python3 "$HOME/.config/rmpc/scripts/fetch_lyrics.py" "$TITLE by $ARTIST" --save-path="$LRC_PATH" --synced-only
  notify-send "Fetching lyrics for $TITLE by $ARTIST..."
else
  echo "LRC file already exists for $TITLE by $ARTIST. Skipping download."
fi
