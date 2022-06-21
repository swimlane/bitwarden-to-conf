#!/bin/bash
secret () {
    name=$(echo "$1" | jq -r '.attachments[0].fileName')
    id=$(echo "$1" | jq -r '.id')
    bw get attachment "${name}" --itemid "${id}" --output './secrets/'
    chmod a+rwx "./secrets/${name}"
}

status=$(bw status | jq -r '.status')
if [[ "$status" != 'unlocked' ]]; then
    session_cmd=$(bw unlock | grep "$ export BW_SESSION")
    ${session_cmd:1}
fi
bw sync

folderid=$(bw list folders | jq -r ".[]|select(.name==\"${1}\")|.id")
items=$(bw list --folderid "${folderid}" items)

for row in $(echo "${items}" | jq -r '.[]|select(.type==1)|@base64'); do
    login=$(echo "${row}" | base64 --decode)
    name=$(echo "${login}" | jq -r '.name')
    export "${name}_password"="$(echo "${login}" | jq -r '.login.password')"
    export "${name}_username"="$(echo "${login}" | jq -r '.login.username')"
    export "${name}"="$(echo "${login}" | jq -r '.notes')"
done

for row in $(echo "${items}" | jq -r '.[]|select(.type==2)|@base64'); do
    secret "$(echo "${row}" | base64 --decode)"
done
