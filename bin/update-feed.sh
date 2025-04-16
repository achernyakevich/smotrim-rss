#!/bin/bash

PODCAST_ID=$1
SCRIPT_FLAGS=$2

FEEDS_BASE_DIR="./feeds"
PODCAST_FEED_DIR="$FEEDS_BASE_DIR/$PODCAST_ID"
PODCAST_HEADER_PATH="$PODCAST_FEED_DIR/rss-$PODCAST_ID.header"
PODCAST_RSS_PATH="./tmp/rss-$PODCAST_ID.xml"
PODCAST_JSON_PATH="./tmp/items-$PODCAST_ID.json"
TEMPLATE_ITEM_PATH="./templates/feed.item"

PODCAST_API_PAGE_SIZE="1000"
PODCAST_API_URL="https://smotrim.ru/api/audios?page=1&limit=$PODCAST_API_PAGE_SIZE&rubricId=$PODCAST_ID"

if [ -z "$PODCAST_ID" ]; then
    echo -e "Usage:\t./bin/update-feed.sh <podcast_id>"
    echo -e "\nUpdate RSS feed for smotrim.ru podcast with <podcast_id>.\n"
    exit 1
else
    if ! [[ "$PODCAST_ID" =~ ^[0-9]+$ ]]; then
        echo -e "Error:\twrong podcast id format (it should be number).\n"
        exit 2
    fi
fi

if [ ! -d "$PODCAST_FEED_DIR" ] || [ ! -f "$PODCAST_HEADER_PATH" ] ; then
    echo -e "Error:\tpodcast's feed folder or RSS header do not exist.\n"
    echo -e "Check podcast id or RSS folder ($PODCAST_FEED_DIR) or add RSS first (use ./bin/add-feed.sh $PODCAST_ID).\n"
    exit 3
fi


cp $PODCAST_HEADER_PATH $PODCAST_RSS_PATH

echo "Getting podcast JSON from $PODCAST_API_URL (last $PODCAST_API_PAGE_SIZE items)."
curl -s "$PODCAST_API_URL" > "$PODCAST_JSON_PATH"

jq -r '.contents[0].list[] | 
      [.id, .anons, .description, .duration, .preview.source.main, 
      ("https://vgtrk-podcast.cdnvideo.ru/audio/listen?id=" + (.id|tostring)), 
      .published] | 
      @tsv' "$PODCAST_JSON_PATH" |
while IFS=$'\t' read -r ITEM_ID ITEM_TITLE ITEM_DESCRIPTION ITEM_DURATION \
                        ITEM_IMAGE ITEM_ENCLOSURE \
                        ITEM_PUBLICATION_DATE; do
    ITEM_PUBLICATION_DATE=$(echo "$ITEM_PUBLICATION_DATE" | ./bin/utils/convert-date.sh)
    awk -v itemId="$ITEM_ID" -v title="$ITEM_TITLE" -v description="$ITEM_DESCRIPTION" \
        -v duration="$ITEM_DURATION" -v imageUrl="$ITEM_IMAGE" \
        -v enclosure="$ITEM_ENCLOSURE" -v publicationDate="$ITEM_PUBLICATION_DATE" \
        '{
            gsub(/{ITEM_ID}/, itemId); gsub(/{TITLE}/, title); gsub(/{DESCRIPTION}/, description);
            gsub(/{DURATION}/, duration); gsub(/{IMAGE_URL}/, imageUrl);
            gsub(/{ENCLOSURE}/, enclosure); gsub(/{PUBLICATION_DATE}/, publicationDate);
            print;
        }' "$TEMPLATE_ITEM_PATH" >> "$PODCAST_RSS_PATH"
done

cat <<EOF >> "$PODCAST_RSS_PATH"
  </channel>
</rss>
EOF

# copying final version of header and RSS to the feed's folder
cp "$PODCAST_RSS_PATH" "$PODCAST_FEED_DIR"

# Clean Up ./tmp folder
if ! [[ $SCRIPT_FLAGS =~ "KEEPTMP" ]]; then
    echo "Clean up for $PODCAST_ID:"
    rm -vrf ./tmp/*$PODCAST_ID*
fi

# Add to VCS and commit feed's folder
if [[ $SCRIPT_FLAGS =~ "COMMIT" ]]; then
    echo "Adding podcast feed updates to VCS..."
    git -C "$FEEDS_BASE_DIR" add "$PODCAST_ID"
    if git -C "$FEEDS_BASE_DIR" diff --staged --quiet; then
        echo "No changes to commit for podcast $PODCAST_ID."
    else
        CURRENT_DATETIME=$(date +"%Y-%m-%d %H:%M")
        COMMIT_MESSAGE="Updated Feed: $PODCAST_ID - $CURRENT_DATETIME"

        git -C "$FEEDS_BASE_DIR" commit -m "$COMMIT_MESSAGE"
        echo "Committed changes for podcast $PODCAST_ID with message: $COMMIT_MESSAGE"
    fi
fi
