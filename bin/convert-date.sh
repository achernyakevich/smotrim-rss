original_date=$1

date_eng=$(echo $original_date | \
           sed -e 's/января/Jan/' \
               -e 's/февраля/Feb/' \
               -e 's/марта/Mar/' \
               -e 's/апреля/Apr/' \
               -e 's/мая/May/' \
               -e 's/июня/Jun/' \
               -e 's/июля/Jul/' \
               -e 's/августа/Aug/' \
               -e 's/сентября/Sep/' \
               -e 's/октября/Oct/' \
               -e 's/ноября/Nov/' \
               -e 's/декабря/Dec/')

formatted_date=$(date -d "$date_eng" -u +"%a, %d %b %Y %H:%M:%S GMT")

echo $formatted_date