#!/bin/bash

PODCAST_ID=$1
SCRIPT_FLAGS=$2

FEEDS_BASE_DIR="./feeds"
PODCAST_FEED_DIR="$FEEDS_BASE_DIR/$PODCAST_ID"
PODCAST_HEADER_PATH="$PODCAST_FEED_DIR/rss-$PODCAST_ID.header"
PODCAST_RSS_PATH="./tmp/rss-$PODCAST_ID.xml"
PODCAST_JSON_PATH="./tmp/items-$PODCAST_ID.json"

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

cat "$PODCAST_JSON_PATH" | jq -c '.contents[0].list[]' | while read -r ITEM; do
    ITEM_ID="$(echo $ITEM | jq -r '.id')"
    ITEM_TITLE=$(echo $ITEM | jq -r '.anons')
    ITEM_DESCRIPTION=$(echo $ITEM | jq -r '.description')
    ITEM_DURATION=$(echo $ITEM | jq -r '.duration')
    ITEM_IMAGE=$(echo $ITEM | jq -r '.preview.source.main')
    ITEM_ENCLOSURE="https://vgtrk-podcast.cdnvideo.ru/audio/listen?id=$(echo $ITEM | jq -r '.id')"

    ITEM_PUBLICATION_DATE=$(echo $ITEM | jq -r '.published' | ./bin/utils/convert-date.sh)

    cat <<EOF >> "$PODCAST_RSS_PATH"
    <item>
      <title>$ITEM_TITLE</title>
      <description>
        <![CDATA[$ITEM_DESCRIPTION]]>
      </description>
      <link>https://radiomayak.ru/shows/episode/id/$ITEM_ID/</link>
      <guid isPermaLink="true">$ITEM_ENCLOSURE</guid>
      <pubDate>$ITEM_PUBLICATION_DATE</pubDate>
      <enclosure url="$ITEM_ENCLOSURE" type="audio/mpeg"/>
      <itunes:title>$ITEM_TITLE</itunes:title>
      <itunes:summary>
        <![CDATA[$ITEM_DESCRIPTION]]>
      </itunes:summary>
      <itunes:duration>$ITEM_DURATION</itunes:duration>
      <itunes:image href="$ITEM_IMAGE"/>
    </item>
EOF
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
    echo TODO
fi
