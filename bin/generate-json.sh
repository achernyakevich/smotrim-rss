#!/bin/bash

FEEDS_BASE_DIR="./feeds"
FEEDS_JSON_PATH="$FEEDS_BASE_DIR/feeds.json"
FEEDS_JSON=()

GENERATE_JSON() {
    local DIRECTORY=$1

    for FILE in "$DIRECTORY"/*; do
        local BASE_NAME=$(basename "$FILE")

        if [ -d "$FILE" ] && [[ $BASE_NAME =~ ^[0-9]+$ ]]; then
            local HEADER_FILE="$FILE/rss-$BASE_NAME.header"

            if [ -f "$HEADER_FILE" ]; then
                local TITLE=$(grep -oP "(?<=<title>).*?(?=</title>)" "$HEADER_FILE" | head -n 1 | xargs)
                local DESCRIPTION=$(grep -oP "(?<=<description>).*?(?=</description>)" "$HEADER_FILE" | head -n 1 | xargs)
                local IMAGE_URL=$(grep -oP "(?<=<url>).*?(?=</url>)" "$HEADER_FILE" | head -n 1 | xargs)

                local ID=$BASE_NAME

                FEEDS_JSON+=("$(jq -n --arg title "$TITLE" --arg description "$DESCRIPTION" --arg imageUrl "$IMAGE_URL" --arg id "$ID" \
                   '{id: $id, title: $title, description: $description, image_url: $imageUrl}')")
            fi
        fi
    done
}

GENERATE_JSON "$FEEDS_BASE_DIR"

printf '%s\n' "${FEEDS_JSON[@]}" | jq -s 'sort_by(.title)' > $FEEDS_JSON_PATH
