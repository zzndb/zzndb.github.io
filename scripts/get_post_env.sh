#!/usr/bin/env bash
# by zzndb

FILE=$(printf "%s" "$(git show --pretty='' --name-only | tr -d '"' | tr ' ' '-' | grep '.*.md$')")
[[ $(echo -e "$FILE" | wc -l) != "1" ]] && exit 1
POST=${FILE#content} # delete pre 'content' 
POST=${POST/.md/\/}   # replace '.md' with '/'
POST_ENCO=$(node <<< "console.log(encodeURI('$POST'))")
POST_HASH=$(node <<< "console.log(require('crypto').createHash('md5').update('$POST_ENCO', 'utf-8').digest('hex'))")
POST_LINK="https://zzndb.github.io$POST"
POST_NAME=${POST#/posts/} # delete start '/posts/'
POST_NAME=${POST_NAME%/}  # delete end '/'
echo "::set-env name=post_name::${POST_NAME}"
echo "::set-env name=post_hash::${POST_HASH}"
echo "::set-env name=post_url::${POST_LINK}"
exit 0