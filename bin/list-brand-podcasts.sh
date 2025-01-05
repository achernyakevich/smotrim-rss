#!/bin/bash

BRAND_ID=$1
SCRIPT_FLAGS=$2

PODCASTS_JSON_PATH="./tmp/brand-items-$BRAND_ID.json"

PODCASTS_API_PAGE_SIZE="1000"
PODCASTS_API_URL="https://smotrim.ru/api/podcasts?brandId=$BRAND_ID&limit=$PODCASTS_API_PAGE_SIZE&page=1"

if [ -z "$BRAND_ID" ]; then
    echo -e "Usage:\t./bin/list-brand-podcasts.sh <brand_id>"
    echo -e "\nList podcasts of <brand_id> brand on smotrim.ru.\n"
    exit 1
else
    if ! [[ "$BRAND_ID" =~ ^[0-9]+$ ]]; then
        echo -e "Error:\twrong brand id format (it should be number).\n"
        exit 2
    fi
fi

echo "Getting brand JSON from $PODCASTS_API_URL (last $PODCASTS_API_PAGE_SIZE items)."
echo ""

curl -s "$PODCASTS_API_URL" > "$PODCASTS_JSON_PATH"

jq -r '.contents[].list[] | "\(.title) (\(.id))"' "$PODCASTS_JSON_PATH"

# Clean Up ./tmp folder
if ! [[ $SCRIPT_FLAGS =~ "KEEPTMP" ]]; then
    echo ""
    echo "Clean up for $BRAND_ID:"
    rm -vrf $PODCASTS_JSON_PATH
fi
