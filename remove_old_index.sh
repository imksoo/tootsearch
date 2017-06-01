#!/bin/bash

. .env

INDEX_LIST=$( curl -s "$ES_HOST:$ES_PORT/_cat/indices?index=mastodon-*" | awk '{print $3}' | sort )
INDEX_COUNT=$( echo "$INDEX_LIST" | wc -l )
RETENTION_COUNT=$(( 24 * 3 ))
OLD_INDEX_COUNT=$(( $INDEX_COUNT - $RETENTION_COUNT ))

if [ $OLD_INDEX_COUNT -ge 1 ] ; then
  OLD_INDEX_LIST=$( echo "$INDEX_LIST" | head -n $OLD_INDEX_COUNT )
  echo "$OLD_INDEX_LIST" | xargs -I@ curl -s -X DELETE $ES_HOST:$ES_PORT/@ > /dev/null
fi
