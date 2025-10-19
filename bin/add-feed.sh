#!/bin/bash

PODCAST_ID=$1
SCRIPT_FLAGS=$2

MAPPING_PATH="./bin/utils/mapping.json"
FEEDS_BASE_DIR="./feeds"
PODCAST_FEED_DIR="$FEEDS_BASE_DIR/$PODCAST_ID"
PODCAST_HTML_PATH="./tmp/podcast-$PODCAST_ID.html"
PODCAST_JSON_PATH="./tmp/podcast-$PODCAST_ID.json"
PODCAST_HEADER_PATH="./tmp/rss-$PODCAST_ID.header"
PODCAST_RSS_PATH="./tmp/rss-$PODCAST_ID.xml"

if [ -z "$PODCAST_ID" ]; then
    echo -e "Usage:\t./bin/add-feed.sh <podcast_id>"
    echo -e "\nAdd empty RSS feed for smotrim.ru podcast with <podcast_id>.\n"
    exit 1
else
    if ! [[ "$PODCAST_ID" =~ ^[0-9]+$ ]]; then
        echo -e "Error:\twrong podcast id format (it should be number).\n"
        exit 2
    fi
fi

if [ -d "$PODCAST_FEED_DIR" ]; then
    echo -e "Error:\tpodcast's feed folder already exists ($PODCAST_FEED_DIR)."
    echo -e "\tCheck podcast id or remove target RSS folder.\n"
    exit 3
fi


RESPONSE=$(curl -s -w '%{http_code}' -o "$PODCAST_HTML_PATH" "https://smotrim.ru/podcast/$PODCAST_ID")
STATUS=$(echo $RESPONSE | awk '{print $NF}')
if [ "$STATUS" -ne 200 ]; then
    echo -e "Error:\tcan't download podcast's HTML (URL: https://smotrim.ru/podcast/$PODCAST_ID, HTTP Status: $STATUS)\n"
    exit 1
fi

curl -s -X 'POST' 'https://api.d2d.work/document/process' \
  -H 'accept: application/json' \
  -H 'Content-Type: multipart/form-data' \
  -F "document=@$PODCAST_HTML_PATH" \
  -F "metadata=@$MAPPING_PATH" \
| jq '{"channel": .result.channel}' > $PODCAST_JSON_PATH

jq -r '
  def json2xml(indent):
    . as $in
    | reduce to_entries[] as $el (
        "";
        . + "\n" + indent + "<\($el.key)>" +
        (
          if $in[$el.key] | type == "object" then
            "\($in[$el.key] | json2xml(indent+"  "))\n" + indent
          elif $in[$el.key] | type == "array" then
            "\($in[$el.key][] | json2xml(indent+"  "))"
          else
            "\($in[$el.key])"
          end
        ) +
        "</\($el.key)>"
    );
  "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
  "<rss version=\"2.0\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:content=\"http://purl.org/rss/1.0/modules/content/\" xmlns:atom=\"http://www.w3.org/2005/Atom\" xmlns:itunes=\"http://www.itunes.com/dtds/podcast-1.0.dtd\">" +
  (json2xml("  "))
' "$PODCAST_JSON_PATH" > "$PODCAST_HEADER_PATH"
sed -i '/<\/channel>/d' "$PODCAST_HEADER_PATH"
sed -i 's|https://cdn-st1.smotrim.ru/vh/pictures/r/|https://cdn-st1.smotrim.ru/vh/pictures/it/|g' "$PODCAST_HEADER_PATH"

cp "$PODCAST_HEADER_PATH" "$PODCAST_RSS_PATH" && echo -e "  </channel>\n</rss>" >> "$PODCAST_RSS_PATH"


# copying final version of header and RSS to the feed's folder
mkdir "$PODCAST_FEED_DIR"
cp "$PODCAST_HEADER_PATH" "$PODCAST_FEED_DIR"
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
