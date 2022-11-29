#!/bin/bash

set -e

while read line
do
    echo "--------------------------------"
    sub=$(git log --oneline -1 --pretty=format:%s $line)
    echo "Apllying $line - $sub"
    git cherry-pick -x -s $line
    sleep 1
done < /tmp/commits.txt

