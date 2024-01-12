#!/bin/bash

FEEDS_BASE_DIR="./feeds"
FEEDS_JSON=()

for FEED_FOLDER in ""$FEEDS_BASE_DIR/*""; do
    FEED_ID=$(basename "$FEED_FOLDER")

    if [ -d "$FEED_FOLDER" ] && [[ $FEED_ID =~ ^[0-9]+$ ]]; then
        HEADER_FILE_PATH="$FEED_FOLDER/rss-$FEED_ID.header"

        if [ -f "$HEADER_FILE_PATH" ]; then
            TITLE=$(grep -oP "(?<=<title>).*?(?=</title>)" "$HEADER_FILE_PATH")
            DESCRIPTION=$(grep -oP "(?<=<description>).*?(?=</description>)" "$HEADER_FILE_PATH")
            IMAGE_URL=$(grep -oP "(?<=<url>).*?(?=</url>)" "$HEADER_FILE_PATH")

            FEEDS_JSON+=("$(jq -n \
                               --arg title "$TITLE" \
                               --arg description "$DESCRIPTION" \
                               --arg imageUrl "$IMAGE_URL" \
                               --arg id "$FEED_ID" \
                               '{id: $id, title: $title, description: $description, imageUrl: $imageUrl}')")
        fi
    fi
done

echo ${FEEDS_JSON[@]} | jq -s 'sort_by(.title)'
