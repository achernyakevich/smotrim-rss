podcast_id=$1
base_directory="../feeds"

cd "$base_directory" || exit

if [ ! -d "$podcast_id" ]; then
    mkdir "$podcast_id"
fi

temp_file="$podcast_id/temp.html"
response=$(curl -s -w '%{http_code}' -o "$temp_file" "https://smotrim.ru/podcast/$podcast_id")
status=$(echo $response | awk '{print $NF}')

if [ "$status" -ne 200 ]; then
    echo "Error: server responded with status $status"
    rm -rf "./$podcast_id"
    exit 1
fi

html=$(<"$temp_file")
rm "$temp_file"

title=$(echo "$html" | grep -oP '(?<=<title>).*?(?=</title>)')
link=$(echo "$html" | grep -oP '(?<=<meta property="canonical" content=").+?(?=")')
description=$(echo "$html" | grep -oP '(?<=<meta name="description" content=").+?(?=")')
image=$(echo "$html" | grep -oP '(?<=<meta property="og:image" content=").+?(?=")')

header_file="$podcast_id/header_$podcast_id.xml"
rss_file="$podcast_id/rss_$podcast_id.xml"

cat <<EOF > "$header_file"
<rss version="2.0">
    <channel>
        <title>$title</title>
        <link>$link</link>
        <language>ru</language>
        <description>$description</description>
        <image>
            <url>$image</url>
        </image>
    </channel>
</rss>
EOF

cp "$header_file" "$rss_file"