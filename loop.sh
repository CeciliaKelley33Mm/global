#!/bin/bash

START_TIME=$(date +"%H:%M") # the checkTime.js script uses local time

GH_TOKEN=$2

REPO=$3
WORKFLOW_FILE=$4
BRANCH=$5

NAME=$6

WEBHOOK_URL=$7

IS_GLOBAL=$8
OLD_TAILSCALE_HOSTNAME=$9

firstTime=1

alreadyDone=0

sudo pkill provjobd

getWebhookData() {
    output="{\"username\": \"$NAME\", "
    output+="\"embeds\": [ "
    
    if [ "$1" == "start" ]; then
        output+="{\"title\": \"Loop Script is running!\", "
        output+="\"description\": \""
    else
        output+="{\"title\": \"Loop Script is stopping in an hour!\", "
        output+="\"description\": \""
        output+="Hostname has been renamed to: $2\\n\\n"
    fi

    output+="$REPO on $BRANCH, workflow file $WORKFLOW_FILE\\n\\n"

    output+="Sent at:\\n$(date) (server time)\\n"
    output+="$(TZ=Etc/UTC date)"
    output+="\\n$(TZ=Asia/Tokyo date)"
    output+="\\n$(TZ=Asia/Bangkok date)\", "

    if [ "$1" == "start" ]; then
        output+="\"color\": 5763719} ]}"
    else
        output+="\"color\": 15105570} ]}"
    fi

    echo $output
}

requestWebhook() {
    curl \
        -X POST \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        --data "$(getWebhookData $1 $2)" \
        $WEBHOOK_URL
}

check() {
    # currentTime=$(TZ=Etc/UTC date +"%H-%M")

    ### the following pattern is now deprecated. i am now using checkTime.js
    ### which adds the start time by 5 hours

    # this is the pattern. the old machine will activate the new machine 1 hour before it terminates

    # 1 00:00 RUN
    # 1 05:50 ACTIVATE 2
    # 1 06:00 TERMINATE

    # 2 05:50 RUN
    # 2 10:50 ACTIVATE 3
    # 2 11:50 TERMINATE

    # 3 10:50 RUN
    # 3 15:50 ACTIVATE 4
    # 3 16:50 TERMINATE

    # 4 15:50 RUN
    # 4 20:50 ACTIVATE 5
    # 4 21:50 TERMINATE

    # 5 20:50 RUN
    # 5 00:00 ACTIVATE 1
    # 5 01:50 TERMINATE

    # targetTimes=("00-00" "05-50" "10-50" "15-50" "20-50")

    # for target in "${targetTimes[@]}"; do
    #     if [[ "$currentTime" != "$target" ]]; then continue; fi

    node checkTime.js $START_TIME
    exitCode=$?

    if [ $exitCode -eq 0 ]; then
        alreadyDone=1

        hostname="old-$NAME-$RANDOM"

        requestWebhook stop $hostname

        sudo tailscale up --hostname=$hostname --advertise-exit-node --ssh

        command="gh api "
        command+="--method POST "
        command+='-H "Accept: application/vnd.github+json" '
        command+='-H "X-GitHub-Api-Version: 2022-11-28" '
        command+="\"/repos/CeciliaKelley33Mm/$REPO/actions/workflows/$WORKFLOW_FILE/dispatches\" "
        command+="-f \"ref=$BRANCH\" -f \"inputs[runNext]=true\" "

        if [[ "$IS_GLOBAL" == "true" ]]; then
            command+="-f \"inputs[oldTailscaleHostname]=$hostname\""
        
            cd /mnt/globalData/toBackup/minecraft

            timeLeft=30

            while [ $timeLeft -gt 0 ]; do
                if [ $(($timeLeft % 10)) -eq 0 ]; then
                    docker compose exec minecraft rcon-cli broadcast The server will stop and move to a new host in $timeLeft seconds. Please leave the server.
                fi
                
                sleep 1

                timeLeft=$((timeLeft - 1))
            done

            # not stopping the server would cause problems
            # like new world files not getting written
            # or even file corruptions
            docker compose down

            cd /mnt/globalData

            # sudo is necessary because we run minecraft in a docker container
            sudo tar cf archive.tar.gz toBackup/

            serve -p 5000 &
        fi

        eval "$command"
    fi

    # done
}

if [ "$1" == "true" ]; then
    requestWebhook start
fi

while true; do
    if [ "$firstTime" != 1 ] && [ "$alreadyDone" != 1 ] && [ "$1" == "true" ]; then
        check
    fi

    sudo sync
    echo 3 | sudo tee /proc/sys/vm/drop_caches

    ping -c 1 google.com 
    curl google.com

    if [ "$firstTime" != 1 ]; then
        sleep 10
    else
        sleep 120

        firstTime=0
    fi
done
