#!/bin/bash

file="CHANGELOG.md"

function  addCurrentRelease() {
    echo "Generating CHANGELOG.md header"

    local version_new="$1"
    local version_current="$2"
    local git_root="$5"
    local release_date=$(date)

    if [ ! -f "${git_root}"/${file} ]; then
        tee <<- EOF >  /tmp/${file}
### Add your new changelog entry above this line
### dummy line to prevent git conflicts
### dummy line to prevent git conflicts
## Current Release
### ${version_new}
**Release Date:** ${release_date}
EOF
    else

    tee <<- EOF >  /tmp/${file}
## Current Release 
### ${version_new} 
**Release Date:** ${release_date}     
## Previous Releases 
$(cat "${git_root}"/${file} | sed -e '/## Current Release/d' -e '/## Previous Releases/d' -e '/### Add your new changelog entry above this line/d' -e '/### dummy line to prevent git conflicts/d')

EOF
    fi
    cp /tmp/${file}  "${git_root}"/${file}


    git add ${file}
    #git commit --amend -m "[skip ci] Reving to ${version_new} - $(git log -1 --pretty=%B)"
    git commit -m "[skip ci] Reving to ${version_new} - $(git log -1 --pretty=%B)"
}
function join() {
    local separator=$1
    local elements=$2
    shift 2 || shift $(($#))
    printf "%s" "$elements${@/#/$separator}"
}

case "${1}" in
    --about )
        echo -n "Check ${file} has been updated."
        ;;
    * )
        addCurrentRelease "$@"
        ;;
esac
