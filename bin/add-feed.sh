#!/bin/bash

PODCAST_ID=$1
BASE_DIRECTORY="../feeds"

cd "$BASE_DIRECTORY" || exit

if [ ! -d "$PODCAST_ID" ]; then
    mkdir "$PODCAST_ID"
fi

TEMP_FILE="$PODCAST_ID/temp.html"
RESPONSE=$(curl -s -w '%{http_code}' -o "$TEMP_FILE" "https://smotrim.ru/podcast/$PODCAST_ID")
STATUS=$(echo $RESPONSE | awk '{print $NF}')

if [ "$STATUS" -ne 200 ]; then
    echo "Error: server responded with status $STATUS"
    rm -rf "./$PODCAST_ID"
    exit 1
fi

HTML=$(<"$TEMP_FILE")
rm "$TEMP_FILE"

METADATA_FILE="../bin/mapping.txt"
TEMP_HTML_FILE="$PODCAST_ID/temp_html.html"

echo $HTML > "$TEMP_HTML_FILE"

API_RESPONSE=$(curl -s -X 'POST' \
  'https://api.d2d.work/document/process' \
  -H 'accept: application/json' \
  -H 'Content-Type: multipart/form-data' \
  -F "document=@$TEMP_HTML_FILE" \
  -F "metadata=@$METADATA_FILE")

rm "$TEMP_HTML_FILE"

TITLE=$(echo "$API_RESPONSE" | jq -r '.result.title')
LINK=$(echo "$API_RESPONSE" | jq -r '.result.link')
DESCRIPTION=$(echo "$API_RESPONSE" | jq -r '.result.description')
IMAGE=$(echo "$API_RESPONSE" | jq -r '.result.image')

HEADER_FILE="$PODCAST_ID/header_$PODCAST_ID.xml"
RSS_FILE="$PODCAST_ID/rss_$PODCAST_ID.xml"

cat <<EOF > "$HEADER_FILE"
<rss version="2.0">
    <channel>
        <title>$TITLE</title>
        <link>$LINK</link>
        <language>ru</language>
        <description>$DESCRIPTION</description>
        <image>
            <url>$IMAGE</url>
        </image>
    </channel>
</rss>
EOF

cp "$HEADER_FILE" "$RSS_FILE"
