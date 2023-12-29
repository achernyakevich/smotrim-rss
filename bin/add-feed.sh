#!/bin/bash

PODCAST_ID=$1
if [ -z "$PODCAST_ID" ]; then
    echo -e "Usage:\t./bin/add-feed.sh <podcast_id>"
    echo -e "\nAdd empty RSS feed for smotrim.ru podcast with <podcast_id>."
else
    if ! [[ "$PODCAST_ID" =~ ^[0-9]+$ ]]; then
        echo "Error: wrong podcast id format (it should be number)."
        exit 1
    fi
fi


MAPPING_PATH="./bin/mapping.json"
FEEDS_BASE_DIR="./feeds"
PODCAST_FEED_DIR="$FEEDS_BASE_DIR/$PODCAST_ID"
HEADER_FILE_PATH="$PODCAST_FEED_DIR/header_$PODCAST_ID.xml"
RSS_FILE_PATH="$PODCAST_FEED_DIR/rss_$PODCAST_ID.xml"

if [ -d "$PODCAST_FEED_DIR" ]; then
    echo "Error: podcast's feed folder already exists ($PODCAST_FEED_DIR). Check podcast id or remove target RSS folder."
    exit 3
fi
mkdir "$PODCAST_FEED_DIR"


PODCAST_HTML_PATH="./tmp/podcast-$PODCAST_ID.html"
RESPONSE=$(curl -s -w '%{http_code}' -o "$PODCAST_HTML_PATH" "https://smotrim.ru/podcast/$PODCAST_ID")
STATUS=$(echo $RESPONSE | awk '{print $NF}')

if [ "$STATUS" -ne 200 ]; then
    echo "Error: can\`t download podcast with id $PODCAST_ID"
    rm -rf "./$PODCAST_ID"
    exit 1
fi

API_RESPONSE=$(curl -s -X 'POST' \
  'https://api.d2d.work/document/process' \
  -H 'accept: application/json' \
  -H 'Content-Type: multipart/form-data' \
  -F "document=@$PODCAST_HTML_PATH" \
  -F "metadata=@$MAPPING_PATH")

rm "$PODCAST_HTML_PATH"

cat <<EOF > "$HEADER_FILE_PATH"
<rss version="2.0">
    <channel>
        <title>$(echo "$API_RESPONSE" | jq -r '.result.title')</title>
        <link>$(echo "$API_RESPONSE" | jq -r '.result.link')</link>
        <language>ru</language>
        <description>$(echo "$API_RESPONSE" | jq -r '.result.description')</description>
        <image>
            <url>$(echo "$API_RESPONSE" | jq -r '.result.image')</url>
        </image>
    </channel>
</rss>
EOF

cp "$HEADER_FILE_PATH" "$RSS_FILE_PATH"