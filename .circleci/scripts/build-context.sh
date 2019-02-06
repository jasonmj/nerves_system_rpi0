#!/usr/bin/env bash

# Create build context file
# Example:
# build-context.sh /path/to/output.json

OUTPUT="$1"
TAGS="$2"
FW="$3"

print_csv() {
    values="$*"
    comma=""
    for value in $values; do
       printf "%s\"%s\"" "$comma" "$value"
       comma=", "
    done
    printf "\n"
}

export NERVES_TEST_TAGS=$(print_csv $TAGS)

[ -n "$FW" ] || FW=$(ls ./_build/*/nerves/images/*.fw 2> /dev/null | head -n 1)

FW_METADATA=$(fwup -m -i $FW | jq -n -R 'reduce inputs as $i ({}; . + ($i | (match("([^=]*)=\"(.*)\"") | .captures | {(.[0].string) : .[1].string})))')
BUILD_CONTEXT=$(echo "{}" | jq '{
  "sha" : env.CIRCLE_SHA1,
  "repo_name" : env.CIRCLE_PROJECT_REPONAME,
  "repo_org" : env.CIRCLE_PROJECT_USERNAME,
  "branch" : env.CIRCLE_BRANCH,
  "pr" : env.CIRCLE_PULL_REQUEST,
  "ci" : "circleci",
  "ci_build_number" : env.CIRCLE_BUILD_NUM,
  "ci_build_url" : env.CIRCLE_BUILD_URL,
  "tags" : [env.NERVES_TEST_TAGS]
}')

echo "$FW_METADATA $BUILD_CONTEXT" | jq -s add >> $OUTPUT