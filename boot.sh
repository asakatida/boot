#!/bin/sh
# curl --output /tmp/boot.sh https://raw.githubusercontent.com/asakatida/boot/master/boot.sh
# chmod 700 /tmp/boot.sh
# /tmp/boot.sh

set -ex

case "$(uname)" in
  Darwin )
    os=osx
    ;;
  Linux )
    if command -v apk; then
      os=alpine
    elif command -v apt; then
      os=ubuntu
    else
      os=linux
    fi
    ;;
  * )
    uname
    echo 'unknown os'
    exit
    ;;
esac

alias priviledge='env'
if command -v sudo; then
  alias priviledge='sudo'
fi

case "${os}" in
  alpine )
    apk add bash curl git jq openssh
    ;;
  ubuntu )
    echo no | priviledge dpkg-reconfigure dash

    priviledge apt-get update
    priviledge apt-get install -y curl git jq
    ;;
  * )
esac

bin_dir="${HOME}/bin"

if ! test -d "${bin_dir}"; then
  ssh_dir="${HOME}/.ssh"
  rsa_key="${ssh_dir}/id_rsa"

  if test -f "${rsa_key}"; then
    eval "$(ssh-agent -s)"
    ssh-add "${rsa_key}"
  else
    pub_key="${rsa_key}.pub"

    EMAIL="$(curl --fail -u "asakatida:${GITHUB_TOKEN:?}" 'https://api.github.com/user/public_emails')"
    EMAIL="$(echo "${EMAIL}" | jq 'map(select(.primary and .verified and .visibility == "public"))[0].email')"

    echo "${rsa_key}" | ssh-keygen -t rsa -b 4096 -C "${EMAIL}" -N ''
    chmod 700 "${ssh_dir}/"
    chmod 400 "${rsa_key}" "${pub_key}"

    pub_key="$(cat "${pub_key}")"

    env
    read -r ssh_key_title

    curl --fail -u "asakatida:${GITHUB_TOKEN:?}" -X POST -d "$(
      jq -cn --arg key "${pub_key}" --arg title "${ssh_key_title}" '{ "key": $key, "title": $title }'
    )" 'https://api.github.com/user/keys'
  fi

  boot_dir="${HOME}/boot"

  if ! test -d "${boot_dir}/.git/"; then
    rm -rf "${boot_dir:?}/"
    git clone 'git@github.com:asakatida/boot.git' "${boot_dir}"
    chmod 700 "${boot_dir}/boot.sh"
    "${boot_dir}/boot.sh"
    exit
  fi

  git clone 'git@github.com:asakatida/usr-bin.git' "${bin_dir}/"
fi

"${bin_dir}/tools/boot.sh"
