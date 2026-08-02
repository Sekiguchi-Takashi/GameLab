#!/data/data/com.termux/files/usr/bin/bash
cd "$(dirname "$0")"
MSG="${1:-update}"
TOKEN="$(git config --global github.token)"
REPO="GameLab"
USER="Sekiguchi-Takashi"
if [ ! -d .git ]; then
  git init
fi
curl -s -o /dev/null -X POST -H "Authorization: token $TOKEN" \
  https://api.github.com/user/repos -d "{\"name\":\"$REPO\",\"private\":true}"
git add -A
git commit -m "$MSG" || true
git branch -M main
git remote remove origin 2>/dev/null
git remote add origin "https://$USER:$TOKEN@github.com/$USER/$REPO.git"
git push -u origin main --force
