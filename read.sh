#!/bin/bash

url="lspdd.org"
page=1

output=$1
if [ "${output}" = "" ]; then
	output="data"
fi


read_page() {
	lamp=$1
	lamppage=$(wget -q -O - "${url}${lamp}" 2>&1)

	# name/identifier
	name=$(echo "${lamppage}" | sed -n '/<h1>/,/<\/h1>/p' | sed 's/<.*>//g' | paste -s -d' ' | sed 's/  //g' | sed 's/^ //g' | sed 's/ $//g')
	id=$(echo "${lamp}" | sed -e 's/.*\/\([[:digit:]]\+\)/\1/g')
	fullid=$(echo "${lamppage}" | grep -A 2 "full-lamp-name" | tail -1)

	echo "${name}..."

	filename="${output}/${id}_${fullid}.spd"
	truncate -s 0 "${filename}"

	# spectral table
	spectraltbl=$(echo "${lamppage}" | sed -n '/<table class=.*spectral-data-table.*>/,/<\/table>/p' | paste -s -d' ' | sed -e 's/<\/tr>/\n/g'  | sed 's/<[^[:digit:]]*>//g' | sed 's/^ //g' | sed 's/ $//g' | sed -e 's///g')
	# info table

	info=$(echo "${lamppage}" | sed -n '/<table class=.*lampsTable.*>/,/<\/table>/p' | paste -s -d' ' | sed -e 's/<\/tr>/\n/g' | sed -e 's/<[^>]*>//g' | sed 's/^ /# /g' | sed 's/ $//g' | sed -e 's/[[:space:]]\+/ /g' | sed -e 's///g')

	echo -e "
# From lspdd.org
# 
# Name: ${name}
${info}" >> "${filename}"

	# images
	for img in $(echo "${lamppage}" | grep "lamp-top-image" | sed -e 's/.*<img.*src=\(.*\)>.*/\1/g'); do
		echo "# Image: ${img}" >> "${filename}"
	done

	echo -e "# \n${spectraltbl}" >> "${filename}"
}


while :
do
	echo "Reading page $page..."
	lamps=$(wget -q -O - "${url}/app/fr/lamps?page=${page}" 2>&1 | grep one-lamp-show-link | sed -e 's/.*<a href="\(.*\)">.*/\1/g');
	if [ "$?" -ne 0 ] || [ ${#lamps[@]} -le 1 ]; then
		break
	fi

	for lamp in ${lamps}; do
		read_page "${lamp}" &
	done

	let "page=page+1";
done

