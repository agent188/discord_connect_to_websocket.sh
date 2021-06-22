#!/bin/bash
touch /dev/shm/DiscordBot.txt
chmod 700 /dev/shm/DiscordBot.txt
echo -n > /dev/shm/DiscordBot.txt
function HeartBeat()
{
    while true
    do
        CheckPid
        jo op=1 d=null >> /dev/shm/DiscordBot.txt
        sleep 1
    done
}
function CheckPid()
{
        if ! ps -p $pid &>/dev/null; then
           exit
        fi
}
function AsyncProcessing()
{
    
    case "$(echo "$1" | jq -r '.t' )" in
        "MESSAGE_REACTION_ADD")
            echo "[MESSAGE_REACTION_ADD] $1"
            ;;
    esac
}
function AuthenticatedTimeOut()
{
    sleep 5
    echo "[$(date)] Authenticated timed out"
    kill $pid
}
pid=$$
bot=$(curl -sS -H "Authorization: Bot $tokenbot" "https://discord.com/api/gateway/bot")
url=$(echo "$bot" | jq -r '.url')
if [[ ! $url || $url == 'null' ]]; then
    echo 'Failed get url'
    exit 1
fi
while read -r msg
do
    if [[ $(echo "$msg" | jq -r '.t') == "READY" ]]; then
        echo "[$(date)] Authorized as $(echo "$msg" | jq -r '.d.user.username')#$(echo "$msg" | jq -r '.d.user.discriminator')"
        session_id=$(echo "$msg" | jq -r '.d.session_id')
        kill $pidAuthenticatedTimeOut
        unset pidAuthenticatedTimeOut
    fi
    if [[ ! $heartbeat ]]; then
        heartbeat=true
        HeartBeat &
        heartbeatpid=$!
        continue
    fi
    if [[ ! $auth ]]; then
        AuthenticatedTimeOut &
        pidAuthenticatedTimeOut=$!
        echo "[$(date)] authenticated..."
        echo '{ "op": 2, "d": { "token": "'$tokenbot'", "intents": 1026, "properties": { "$os": "linux", "$browser": "disco", "$device": "disco" }, "presence": { "activities": [ { "name": null, "type": 0 } ], "status": "online", "since": null, "afk": false } } }' >> /dev/shm/DiscordBot.txt
        auth=true
    fi
done < <(tail -n 0 -f --pid $pid /dev/shm/DiscordBot.txt | ./websocat "$url/?v=8&encoding=json" --ping-interval 5 --ping-timeout 10 -E -t)
