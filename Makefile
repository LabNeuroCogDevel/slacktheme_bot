id_list.txt:
	curl -d token="$(shell cat .oauth)" https://slack.com/api/users.list | jq -r '.members[]|[.profile.display_name, .name, .id]|@tsv' > $@

# not used by themebot. but useful for emacs anywhere autocomplete
# only custom names are in the api list. standard are on "short_name"
# https://stackoverflow.com/questions/39490865/how-can-i-get-the-full-list-of-slack-emoji-through-api
emoji_list.txt:
	curl -d token="$(shell cat .oauth)" https://slack.com/api/emoji.list | jq -r '.emoji|keys|join("\n")' > $@
	curl https://raw.githubusercontent.com/iamcal/emoji-data/master/emoji.json | jq '.[]|.short_name'|sed 's/"//g' >>$@
