#!/bin/bash
set -eE -o functrace

failure() {
  local lineno=$1
  local msg=$2
  echo "Failed at $lineno: $msg"
}
trap 'failure ${LINENO} "$BASH_COMMAND"' ERR

set -o pipefail

IP_RANGES_FILE="openai-ip-ranges-all.txt"

update() {
  local _arg_crawl_type="${1}"
  local _arg_enable_curl="${2:-false}"

  if [ "${_arg_enable_curl}" == "true" ]; then
    curl --connect-timeout 10 \
      --max-time 10 \
      --retry 5 \
      --retry-delay 5 \
      --retry-max-time 40 \
      -o "stable/${_arg_crawl_type}" \
      https://openai.com/${_arg_crawl_type}
  fi

  jq -r '.prefixes[].ipv4Prefix | split("/")[0]' "stable/${_arg_crawl_type}" >> $IP_RANGES_FILE
  
  jq -r '.prefixes[].ipv4Prefix | split("/")[0]' "stable/${_arg_crawl_type}" > "openai-ip-ranges-${_arg_crawl_type%%\.json}.txt"
}

main() {
  local _arg_enable_curl="${1:-true}"

  echo "[INFO] Download OpenAI IP ranges"

  # See OpenAI documentation: https://platform.openai.com/docs/bots
  crawl_types=("searchbot.json" "chatgpt-user.json" "gptbot.json")

  if [ -f $IP_RANGES_FILE ] ; then
    rm -f $IP_RANGES_FILE
  fi
  
  for crawl_type in "${crawl_types[@]}"; do
    update "${crawl_type}" "${_arg_enable_curl}"
  done

  date > last_update.txt
}

main "$@"
