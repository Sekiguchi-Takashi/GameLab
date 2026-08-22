#!/data/data/com.termux/files/usr/bin/bash
cd "$(dirname "$0")"
TOKEN=$(git config --global github.token)
GHUSER=Sekiguchi-Takashi
REPO=GameLab
API=https://api.github.com/repos/${GHUSER}/${REPO}
git fetch --tags origin
for T in $(git tag --list 'build-*'); do
  ID=$(curl -s -H "Authorization: token ${TOKEN}" "${API}/releases/tags/${T}" | tr -d ' \n' | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)
  if [ -n "$ID" ]; then
    curl -s -o /dev/null -X DELETE -H "Authorization: token ${TOKEN}" "${API}/releases/${ID}"
  fi
  curl -s -o /dev/null -X DELETE -H "Authorization: token ${TOKEN}" "${API}/git/refs/tags/${T}"
  git tag -d "$T" >/dev/null 2>&1
done
printf 'removed build-* tags and releases\n'
