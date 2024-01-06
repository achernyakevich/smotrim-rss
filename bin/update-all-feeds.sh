#!/bin/bash

FEEDS_BASE_DIR="./feeds"
SCRIPT_FLAGS=$1

if [ ! -d "$FEEDS_BASE_DIR" ]; then
    echo -e "Error:\tFeeds directory ($FEEDS_BASE_DIR) does not exist."
    exit 1
fi

for PODCAST_DIR in "$FEEDS_BASE_DIR"/*; do
    if [ -d "$PODCAST_DIR" ]; then
        PODCAST_ID=$(basename "$PODCAST_DIR")
        if ! [[ "$PODCAST_ID" =~ ^[0-9]+$ ]]; then
            echo -e "Error:\t'$PODCAST_ID' looks as invalid Podcast ID (should be a number)."
            continue
        fi
        echo "Updating RSS feed for Podcast ID $PODCAST_ID."
        ./bin/update-feed.sh "$PODCAST_ID" "$SCRIPT_FLAGS"
        echo -e "\n"
    fi
done

echo -e "All feeds updated.\n"

# Show diff between old and new state of feed's folder (git diff based)
if [[ $SCRIPT_FLAGS =~ "SHOWDIFF" ]]; then
    echo -e "Actual changes are:\n"
    git --no-pager diff ./feeds/
    echo -e "\n"
fi
