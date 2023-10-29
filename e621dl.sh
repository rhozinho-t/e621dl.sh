#!/bin/bash

USER_AGENT="e621dl.sh, a bash-based e621 downloader"
BASE_URL="https://e621.net/posts.json"

JQ_QUERY=".posts[].file.url | select(. != null)"
PAGE_CRAWL_SLEEP_INTERVAL=2

complain_and_exit() {
	echo $1
	exit 1
}

warn_no_tags() {
	echo "WARNING!! no tags specified!"
	echo "this will cause e621dl.sh to download every available post on e621!"
	echo "execution will continue in 10 seconds. if this is not intended, please interrupt execution."
	sleep 10
}

main() {
	current_page=0
	tags=$1

	echo "starting"
	[[ -z "$tags" ]] || echo "using tags '$tags'"

	while :; do
		post_list=$(curl -A "$USER_AGENT" --get --data-urlencode "tags=$tags" --data-urlencode "page=$current_page" "$BASE_URL" | jq -r "$JQ_QUERY")
		[[ -z "$post_list" ]] && exit

		echo -n "$post_list" | parallel -v curl -sO

		current_page=$((current_page + 1))
		fetched_posts=$(echo "$post_list" | wc -l)

		echo "fetched $fetched_posts posts; going to the next page"
	done

	echo "finished; downloaded up until page $current_page"
}

command -v jq >/dev/null 2>&1 || complain_and_exit "you need jq installed on your system to use this utility"
command -v parallel >/dev/null 2>&1 || complain_and_exit "you need GNU parallel installed on your system to use this utility"


tags="$1"
[[ -z "$tags" ]] && warn_no_tags

main "$tags"
