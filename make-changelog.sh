#!/bin/bash
# generate a changelog from git tags

TAGLIST=`git tag | grep -E '^v[0-9]+' | xargs -I@ git log --format=format:"%ai @%n" -1 @ | sort -r | awk '{print $4}'`

LAST_IN_LIST=HEAD

echo "Changelog"
echo "---------"
echo ""
echo "Auto-generated from git commits."
echo ""

function git_log {
    START="$1"
    END="$2"
    git --no-pager log --no-merges \
        --format="format:  * %s [%h]" "${START}..${END}"  | fold -w 80 -s | sed -re 's.^([^ \t]).    \1.'
}

for TAG in $TAGLIST; do
    echo "$LAST_IN_LIST   ($(git log -1 --format=%ai "$LAST_IN_LIST"))"
    git_log "$TAG" "$LAST_IN_LIST"
    LAST_IN_LIST=$TAG
    echo ""
    echo ""
done

# changes since first commit
FIRST_COMMIT=`git rev-list --max-parents=0 HEAD`
echo "$LAST_IN_LIST"
git_log "$FIRST_COMMIT" "$LAST_IN_LIST"
git --no-pager log --format="format:  * %s [%h]" "${FIRST_COMMIT}..${LAST_IN_LIST}"
echo ""