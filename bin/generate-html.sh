#!/bin/bash

SCRIPT_FLAGS=$1
FEEDS_JSON_PATH="./feeds/feeds.json"
HTML_HEADER_FILE="./feeds/feeds-html.header"
FEEDS_HTML_PATH="./feeds/feeds.html"

./bin/generate-json.sh

cat "$HTML_HEADER_FILE" > "$FEEDS_HTML_PATH"

jq -c '.[]' "$FEEDS_JSON_PATH" | while read -r FEED; do
  ID=$(echo "$FEED" | jq -r '.id')
  TITLE=$(echo "$FEED" | jq -r '.title')
  DESCRIPTION=$(echo "$FEED" | jq -r '.description')
  IMAGE_URL=$(echo "$FEED" | jq -r '.image_url')

  echo "      <div class=\"row mb-4\">
        <div class=\"col-md-2 d-flex justify-content-center\">
          <img src=\"$IMAGE_URL\" alt=\"$TITLE\" class=\"img-fluid\" />
        </div>
        <div class=\"col-md-10\">
          <h5>
            <a href=\"$ID/rss-$ID.xml\" class=\"stretched-link\">$TITLE</a>
          </h5>
          <p>
            $DESCRIPTION
          </p>
        </div>
      </div>" >> "$FEEDS_HTML_PATH"
done

echo "    </div>
  </body>
</html>" >> "$FEEDS_HTML_PATH"

if [[ $SCRIPT_FLAGS =~ "COMMIT" ]]; then
    echo TODO
fi
