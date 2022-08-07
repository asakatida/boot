#!/bin/sh
# curl --output /tmp/boot.sh https://raw.githubusercontent.com/asakatida/boot/stable/boot.sh
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

priviledge ssh-keygen -A

boot_dir="${HOME}/boot"

if [ ! -f "${boot_dir}/.git" ]; then
  rm -rf "${boot_dir}/"
  git clone 'https://github.com/asakatida/boot.git' "${boot_dir}"
  chmod 700 "${boot_dir}/boot.sh"
  "${boot_dir}/boot.sh"
  exit
fi

bin_dir="${HOME}/bin"

if [ ! -f "${bin_dir}/.git" ]; then
  ssh_dir="${HOME}/.ssh"
  ssh_key="${ssh_dir}/id_ed25519"

  if ! test -f "${ssh_key}"; then
    mkdir -p "${ssh_dir}"
    chmod 700 "${ssh_dir}"

    read -p 'Enter your github token: ' github_token
    read -p 'Enter your github ssh key name: ' ssh_key_title

    pub_key="${ssh_key}.pub"

    if [ -n "${github_token}" ]; then
      email="$(curl --fail -u "asakatida:${github_token:?}" 'https://api.github.com/user/public_emails')"
      email="$(echo "${email}" | jq 'map(select(.primary and .verified and .visibility == "public"))[0].email')"
    else
      email='github@holomaplefeline.net'
    fi

    if test -n "${SSH_KEY:-}"; then
      echo "${SSH_KEY}" > "${ssh_key}"
      ssh-keygen -f "${ssh_key}" -t ed25519 -C "${email}" -N ''
    else
      ssh-keygen -f "${ssh_key}" -t ed25519 -C "${email}" -N ''
    fi
    chmod 400 "${ssh_key}" "${pub_key}"

    if [ -n "${github_token}" ]; then
      pub_key="$(cat "${pub_key}")"

      curl --fail -u "asakatida:${github_token:?}" -X POST -d "$(
        jq -cn --arg key "${pub_key}" --arg title "${ssh_key_title:?}-${HOSTNAME:?}" '{ "key": $key, "title": $title }'
      )" 'https://api.github.com/user/keys'
    fi
  fi

  eval "$(ssh-agent -s)"
  ssh-add "${ssh_key}"

  git clone 'git@github.com:asakatida/usr-bin.git' "${bin_dir}/"
fi

"${bin_dir}/tools/boot.sh"
