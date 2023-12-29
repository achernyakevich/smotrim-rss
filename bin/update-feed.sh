PODCAST_ID=$1
RSS_FILE="../feeds/$PODCAST_ID/rss_$PODCAST_ID.xml"

JSON=$(curl -s "https://smotrim.ru/api/audios?page=1&limit=1000&rubricId=$PODCAST_ID")

sed -i '/<\/channel>/d' "$RSS_FILE"
sed -i '/<\/rss>/d' "$RSS_FILE"

echo "$JSON" | jq -c '.contents[0].list[]' | while read -r ITEM; do
    TITLE=$(echo $ITEM | jq -r '.anons')
    DESCRIPTION=$(echo $ITEM | jq -r '.description')
    LINK="https://smotrim.ru/audio/$(echo $ITEM | jq -r '.id')"
    PUBLISHED=$(echo $ITEM | jq -r '.published')
    DURATION=$(echo $ITEM | jq -r '.duration')
    IMAGE=$(echo $ITEM | jq -r '.preview.source.small')
    ENCLOSURE="https://vgtrk-podcast.cdnvideo.ru/audio/listen?id=$(echo $ITEM | jq -r '.id')"

    PUBDATE=$(./convert-date.sh "$PUBLISHED")

    cat <<EOF >> "$RSS_FILE"
    <item>
        <title>$TITLE</title>
        <description><![CDATA[<img src="$IMAGE" alt="Image description"><br>$DESCRIPTION]]></description>
        <link>$LINK</link>
        <pubDate>$PUBDATE</pubDate>
        <duration>$DURATION</duration>
        <enclosure url="$ENCLOSURE" type="audio/mpeg"/>
    </item>
EOF
done

echo '    </channel>' >> "$RSS_FILE"
echo '</rss>' >> "$RSS_FILE"
