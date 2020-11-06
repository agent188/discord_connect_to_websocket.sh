#!/bin/bash
randomPort=$(shuf -i 2000-65000 -n 1)
echo "LOCALHOST LISTEN $randomPort PORT"
function HeartBeat()
{
    while true
    do
        CheckPid
        jo op=1 d=null > /dev/tcp/localhost/$randomPort
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
pid=$$
bot=$(curl -s -H "Authorization: Bot $tokenbot" "https://discord.com/api/gateway/bot")
url=$(echo "$bot" | jq -r '.url')
while true
do
    while read -r msg
    do
        if [[ $(echo "$msg" | jq -r '.t') == "READY" ]]; then
            echo "[$(date)] Authorized as $(echo "$msg" | jq -r '.d.user.username')#$(echo "$msg" | jq -r '.d.user.discriminator')"
            session_id=$(echo "$msg" | jq -r '.d.session_id')
        fi
        case $(echo "$msg" | jq -r '.op') in
            0)
                AsyncProcessing "$msg" &
                sequence=$(echo "$msg" | jq -r '.s')
                ;;
            7)
                echo "[$(date)] Reconnect..."
                break
                ;;
            9)
                echo "[$(date)] Invalid Session. Stopping bot..."
                exit 1
                ;;
        esac
        if [[ ! $heartbeat ]]; then
            heartbeat=true
            HeartBeat &
            heartbeatpid=$!
            continue
        fi
        if [[ $resume ]]; then
            echo "[$(date)] Resume session"
            jo op=6 d[token]="$tokenbot" d[session_id]="$session_id" d[seq]=$sequence > /dev/tcp/localhost/$randomPort
            unset resume
        fi
        if [[ ! $auth ]]; then
            echo "[$(date)] authenticated..."
            echo '{ "op": 2, "d": { "token": "'$tokenbot'", "intents": 1026, "properties": { "$os": "linux", "$browser": "disco", "$device": "disco" }, "presence": { "activities": [ { "name": null, "type": 0 } ], "status": "online", "since": null, "afk": false } } }' > /dev/tcp/localhost/$randomPort
            auth=true
        fi
    done < <(ncat -kl localhost $randomPort -m 10000000 | ./websocat "$url/?v=8&encoding=json" --ping-interval 1 --ping-timeout 2 -E -t)
    kill $heartbeatpid
    unset heartbeat
    randomPort=$(shuf -i 2000-65000 -n 1)
    echo "LOCALHOST LISTEN $randomPort PORT"
    bot=$(curl -s -H "Authorization: Bot $tokenbot" "https://discord.com/api/gateway/bot")
    url=$(echo "$bot" | jq -r '.url')
    resume=true
done
