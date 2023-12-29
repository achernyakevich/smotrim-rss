#!/bin/bash

PODCAST_ID=$1

if [ "$#" -ne 1 ] || ! [[ "$PODCAST_ID" =~ ^[0-9]+$ ]]; then
    echo "Error: wrong podcast id format"
    exit 1
fi

BASE_DIR="../feeds"
MAPPING_PATH="../bin/mapping.json"
HEADER_FILE="$BASE_DIR/$PODCAST_ID/header_$PODCAST_ID.xml"
RSS_FILE="$BASE_DIR/$PODCAST_ID/rss_$PODCAST_ID.xml"

cd "$BASE_DIR" || exit

if [ -d "$PODCAST_ID" ]; then
    echo "Error: directory '$PODCAST_ID' already exists. Check podcast id or remove this directory"
    exit 3
fi

mkdir "$PODCAST_ID"

PODCAST_PATH="../tmp/podcast.html"
RESPONSE=$(curl -s -w '%{http_code}' -o "$PODCAST_PATH" "https://smotrim.ru/podcast/$PODCAST_ID")
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
  -F "document=@$PODCAST_PATH" \
  -F "metadata=@$MAPPING_PATH")

rm "$PODCAST_PATH"

cat <<EOF > "$HEADER_FILE"
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

cp "$HEADER_FILE" "$RSS_FILE"