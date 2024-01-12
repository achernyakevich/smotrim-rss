#!/bin/bash

SCRIPT_FLAGS=$1
TEMPLATE_HEADER_PATH="./templates/feeds-index.header"
TEMPLATE_FOOTER_PATH="./templates/feeds-index.footer"
TEMPLATE_ITEM_PATH="./templates/feeds-index.item"
FEEDS_HTML_PATH="./feeds/index.html"

cat "$TEMPLATE_HEADER_PATH" > "$FEEDS_HTML_PATH"

./bin/list-feeds-as-json.sh | jq -c '.[]' | while read -r FEED; do
    FEED_ID=$(echo "$FEED" | jq -r '.id')
    TITLE=$(echo "$FEED" | jq -r '.title')
    DESCRIPTION=$(echo "$FEED" | jq -r '.description')
    IMAGE_URL=$(echo "$FEED" | jq -r '.imageUrl')

    awk -v feedId="$FEED_ID" -v title="$TITLE" -v desc="$DESCRIPTION" -v image="$IMAGE_URL" \
        '{gsub(/{FEED_ID}/, feedId); \
          gsub(/{TITLE}/, title); \
          gsub(/{DESCRIPTION}/, desc); \
          gsub(/{IMAGE_URL}/, image); print}' \
        "$TEMPLATE_ITEM_PATH" >> "$FEEDS_HTML_PATH"
done

cat "$TEMPLATE_FOOTER_PATH" >> "$FEEDS_HTML_PATH"

if [[ $SCRIPT_FLAGS =~ "COMMIT" ]]; then
    echo TODO
fi
