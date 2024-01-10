#!/bin/bash

FEEDS_BASE_DIR="./feeds"
FEEDS_HTML_PATH="$FEEDS_BASE_DIR/feeds.html"

if [ ! -d "$FEEDS_BASE_DIR" ]; then
    echo -e "Error:\tFeeds directory ($FEEDS_BASE_DIR) does not exist."
    exit 1
fi

GENERATE_HTML() {
    local DIRECTORY=$1

    for FILE in "$DIRECTORY"/*; do
        local BASE_NAME=$(basename "$FILE")

        if [ -d "$FILE" ] && [[ $BASE_NAME =~ ^[0-9]+$ ]]; then
            echo "        <li>$BASE_NAME" >> $FEEDS_HTML_PATH
            echo "            <ul>" >> $FEEDS_HTML_PATH

            for SUBFILE in "$FILE"/*; do
                if [ -f "$SUBFILE" ]; then
                    echo "                <li><a href='$BASE_NAME/$(basename "$SUBFILE")'>$(basename "$SUBFILE")</a></li>" >> $FEEDS_HTML_PATH
                fi
            done

            echo "            </ul>" >> $FEEDS_HTML_PATH
            echo "        </li>" >> $FEEDS_HTML_PATH
        fi
    done
}

echo "<!DOCTYPE html>
<html>
<head>
    <title>Feeds</title>
</head>
<body>
    <h1>Feeds</h1>
    <ul>" > $FEEDS_HTML_PATH

GENERATE_HTML "$FEEDS_BASE_DIR"

echo "    </ul>
</body>
</html>" >> $FEEDS_HTML_PATH