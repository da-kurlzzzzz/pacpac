#!/usr/bin/env bash
set -euo pipefail

#set -x

run_interactive_playbook()
{
    ansible-playbook add-date-to-file.yml | awk '
        f {print}
        /^: \{$/ {f=1; print("{")}
        !f {sub(/^: /, ""); print >"/dev/stderr"}
    '
}

extract_tasks()
{
    jq '
        .plays[].tasks[].hosts.localhost |
        select(.action as $a | ["gather_facts","set_fact"] | all(. != $a))
    '
}

extract_diff()
{
    jq --raw-output0 '.diff[0]' | while read -r -d '' line
    do
        jq -e <<< "$line" &>/dev/null || continue
        tee <<< "$line" >(jq -r '.before' >/tmp/old) | jq -r '.after' >/tmp/new && diff --color=always -u /tmp/old /tmp/new
    done
}

extract_msg()
{
    extract_tasks | jq -r '.msg'
}

create_diff_from_input()
{
    extract_tasks | extract_diff
}

DIFF=false
TASKS=false
while getopts "dt" opt
do
    case ${opt} in
        d)
            DIFF=true
            ;;
        t)
            TASKS=true
            ;;
        \?)
            echo "Invalid option: -${OPTARG}" >&2
            exit 1
            ;;
    esac
done
shift $((OPTIND -1))

json_output="$(run_interactive_playbook)"
if [ "$DIFF" = true ]
then
    create_diff_from_input <<< "$json_output"
elif [ "$TASKS" = true ]
then
    extract_tasks <<< "$json_output"
else
    extract_msg <<< "$json_output"
fi
