#!/bin/bash

set -e

if [[ $# -ne 2 ]]; then
  echo "usage: $0 session_id title" >&2
  echo "    session_id    is the Session_id cookie from the yandex.ru domain" >&2
  echo "    title         is the title of the list" >&2
  exit 1
fi

SESSION_ID="$1"
TITLE="$2"


info() {
  echo "info: $1" >&2
}


TMP_DIR="$(mktemp -d)"
# info "temp directory is $TMP_DIR"
RESPONSE="$TMP_DIR/resp.json"
LIST="$TMP_DIR/list.json"

curl -s 'https://cloud-api.yandex.ru/maps_common/v1/data/app/databases/.ext.maps_common@ymapsbookmarks1/snapshot' \
  -H 'Origin: https://yandex.ru' \
  -H "Cookie: Session_id=$SESSION_ID" \
  > "$RESPONSE"

cat "$RESPONSE" | jq ".records.items[] | select(.fields[] | .field_id == \"children\") | select(.fields[] | .field_id == \"title\" and .value.string == \"$TITLE\")" > "$LIST"

cat "$LIST" | jq -r '.fields[] | select(.field_id == "children") | .value.list[] | .string' | while read record_id; do
  item="$(cat "$RESPONSE" | jq ".records.items[] | select(.record_id == \"$record_id\")")"
  title="$(echo "$item" | jq -r '.fields[] | select(.field_id == "title") | .value.string')"
  uri="$(echo "$item" | jq -r '.fields[] | select(.field_id == "uri") | .value.string')"

  if [[ "$uri" =~ "ymapsbm1://org?oid=" ]]; then
    oid="$(echo "$uri" | cut -d = -f 2)"
  else
    oid="kek"
  fi

  url="https://yandex.ru/maps/org/$oid"
  echo -e "$title\t$url"
done