#!/bin/bash

clean_up_feed_dir() {
    rm -vrf "$PODCAST_FEED_DIR"
}
clean_up_html() {
    rm -v "$PODCAST_HTML_PATH"
}

PODCAST_ID=$1
SCRIPT_FLAG=$2

MAPPING_PATH="./bin/mapping.json"
FEEDS_BASE_DIR="./feeds"
PODCAST_FEED_DIR="$FEEDS_BASE_DIR/$PODCAST_ID"
HEADER_FILE_PATH="$PODCAST_FEED_DIR/rss_$PODCAST_ID.header"
RSS_FILE_PATH="$PODCAST_FEED_DIR/rss_$PODCAST_ID.xml"
PODCAST_HTML_PATH="./tmp/podcast-$PODCAST_ID.html"

if [ -z "$PODCAST_ID" ]; then
    echo -e "Usage:\t./bin/add-feed.sh <podcast_id>"
    echo -e "\nAdd empty RSS feed for smotrim.ru podcast with <podcast_id>."
else
    if ! [[ "$PODCAST_ID" =~ ^[0-9]+$ ]]; then
        echo "Error: wrong podcast id format (it should be number)."
        exit 1
    fi
fi

if [ -d "$PODCAST_FEED_DIR" ]; then
    echo "Error: podcast's feed folder already exists ($PODCAST_FEED_DIR). Check podcast id or remove target RSS folder."
    exit 3
fi
mkdir "$PODCAST_FEED_DIR"


RESPONSE=$(curl -s -w '%{http_code}' -o "$PODCAST_HTML_PATH" "https://smotrim.ru/podcast/$PODCAST_ID")
STATUS=$(echo $RESPONSE | awk '{print $NF}')

if [ "$STATUS" -ne 200 ]; then
    echo "Error: can't download podcast's HTML (URL: https://smotrim.ru/podcast/$PODCAST_ID, HTTP Status: $STATUS)"
    clean_up_feed_dir
    exit 1
fi

PODCAST_JSON=$(curl -s -X 'POST' \
  'https://api.d2d.work/document/process' \
  -H 'accept: application/json' \
  -H 'Content-Type: multipart/form-data' \
  -F "document=@$PODCAST_HTML_PATH" \
  -F "metadata=@$MAPPING_PATH")

clean_up_html

cat <<EOF > "$HEADER_FILE_PATH"
<rss version="2.0">
  <channel>
    <title>$(echo "$PODCAST_JSON" | jq -r '.result.rss.channel.title')</title>
    <link>$(echo "$PODCAST_JSON" | jq -r '.result.rss.channel.link')</link>
    <language>$(echo "$PODCAST_JSON" | jq -r '.result.rss.channel.language')</language>
    <description>$(echo "$PODCAST_JSON" | jq -r '.result.rss.channel.description')</description>
    <image>
      <url>$(echo "$PODCAST_JSON" | jq -r '.result.rss.channel.image.url')</url>
    </image>
  </channel>
EOF

cp "$HEADER_FILE_PATH" "$RSS_FILE_PATH"
echo "</rss>" >> $RSS_FILE_PATH
