#!/bin/bash
# runner 心跳:每 10 分钟由 launchd 调用,把两个自架 runner 的在线状态与排队时长写进公开 gist(只用别名 A/B)。
# 只用本机 gh 的现有登录;不读取、不导出任何其它凭据。
export PATH=/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin
cd "$(dirname "$0")" || exit 1
GIST=$(cat gist-id)
declare -A REPO=([A]=EmoN-Fang/ToDoApp [B]=EmoN-Fang/ccg)
declare -A NAME=([A]=hz-mac [B]=hz-mac-ccg)
now=$(date -u +%s)
status_json=""; queue_json=""
for k in A B; do
  st=$(gh api "repos/${REPO[$k]}/actions/runners" --jq ".runners[] | select(.name==\"${NAME[$k]}\") | .status" 2>/dev/null || true)
  [ -z "$st" ] && st="api-error"
  qmax=0
  for rid in $(gh api "repos/${REPO[$k]}/actions/runs?status=queued&per_page=10" --jq '.workflow_runs[].id' 2>/dev/null; gh api "repos/${REPO[$k]}/actions/runs?status=in_progress&per_page=10" --jq '.workflow_runs[].id' 2>/dev/null); do
    while read -r created; do
      [ -z "$created" ] && continue
      c=$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$created" +%s 2>/dev/null || echo "$now")
      age=$(( (now - c) / 60 )); [ "$age" -gt "$qmax" ] && qmax=$age
    done < <(gh api "repos/${REPO[$k]}/actions/runs/$rid/jobs?per_page=100" --jq '.jobs[] | select(.status=="queued") | .created_at' 2>/dev/null)
  done
  status_json="$status_json\"$k\":\"$st\","; queue_json="$queue_json\"$k\":$qmax,"
done
printf '{"ts":"%s","epoch":%s,"runners":{%s},"queued_min":{%s}}\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$now" "${status_json%,}" "${queue_json%,}" > heartbeat.json
if gh gist edit "$GIST" -f heartbeat.json heartbeat.json >/dev/null 2>&1; then echo "$(date -u +%FT%TZ) ok $(cat heartbeat.json)"; else echo "$(date -u +%FT%TZ) GIST-UPDATE-FAILED $(cat heartbeat.json)"; fi >> heartbeat.log
tail -n 300 heartbeat.log > heartbeat.log.tmp && mv heartbeat.log.tmp heartbeat.log
