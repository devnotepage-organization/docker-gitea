on_error() {
    echo "[Error] ${BASH_SOURCE[1]}:${BASH_LINENO} - '${BASH_COMMAND}' failed">&2
    if [ "${BASH_COMMAND}" != "git commit -am 'Update'" ]; then
        read -p ""
    fi
}
trap on_error ERR

set LANG=ja_JP.UTF-8
git config --global core.quotepath false

git add .
printf "\n"

git status
printf "\n"

read -p "[Continue]"

# git diff

# read -p "[Commit]"

git commit -am 'Update'
printf "\n"

# read -p "[Sync]"

git pull -v --progress "origin"
printf "\n"

git push -v --progress "origin" master:master
printf "\n"

# read -p "[Complete]"
