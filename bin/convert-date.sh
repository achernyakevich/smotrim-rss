read DATE_RU
DATE_EN=$(echo $DATE_RU | \
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

date -d "$DATE_EN" -u +"%a, %d %b %Y %H:%M:%S GMT"
