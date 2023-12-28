podcast_id=$1
rss_file="..feeds/$podcast_id/rss_$podcast_id.xml"

json=$(curl -s "https://smotrim.ru/api/audios?page=1&limit=1000&rubricId=$podcast_id")

sed -i '/<\/channel>/d' "$rss_file"
sed -i '/<\/rss>/d' "$rss_file"

echo "$json" | jq -c '.contents[0].list[]' | while read -r item; do
    title=$(echo $item | jq -r '.anons')
    description=$(echo $item | jq -r '.description')
    link="https://smotrim.ru/audio/$(echo $item | jq -r '.id')"
    published=$(echo $item | jq -r '.published')
    duration=$(echo $item | jq -r '.duration')
    image=$(echo $item | jq -r '.preview.source.small')
    enclosure="https://vgtrk-podcast.cdnvideo.ru/audio/listen?id=$(echo $item | jq -r '.id')"

    pubDate=$(./convert-date.sh "$published")

    cat <<EOF >> "$rss_file"
    <item>
        <title>$title</title>
        <description><![CDATA[<img src="$image" alt="Image description"><br>$description]]></description>
        <link>$link</link>
        <pubDate>$pubDate</pubDate>
        <duration>$duration</duration>
        <enclosure url="$enclosure" type="audio/mpeg"/>
    </item>
EOF
done

echo '    </channel>' >> "$rss_file"
echo '</rss>' >> "$rss_file"

cat "$rss_file"