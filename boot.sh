#!/bin/sh
# curl --output /tmp/boot.sh https://raw.githubusercontent.com/asakatida/boot/master/boot.sh
# chmod 700 /tmp/boot.sh
# /tmp/boot.sh

set -ex

case "$(/bin/sh --version)" in
  *bash* )
    shell=bash
    set -o pipefail
    ;;
  * )
    echo 'unknown shell'
    exit
    ;;
esac

case "$(uname)" in
  Darwin )
    os=osx
    ;;
  * )
    echo 'unknown os'
    exit
    ;;
esac

case "${os}" in
  osx )
    ;;
  ubuntu )
    case "${shell}" in
      dash )
        sudo dpkg-reconfigure dash

        echo 'bash shell set, rerun command.'
        exit
        ;;
    esac

    sudo apt-get install -y git xclip
    ;;
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

    ssh-keygen -t rsa -b 4096 -C 'github@holomaplefeline.net'
    chmod 700 "${ssh_dir}/"
    chmod 400 "${rsa_key}" "${pub_key}"

    case "${os}" in
      osx )
        pbcopy < "${pub_key}"
        ;;
      ubuntu )
        xclip -sel clip < "${pub_key}"
        ;;
    esac

    echo 'Add key to github.com'
    exit
  fi

  boot_dir="${HOME}/boot"

  if ! test -d "${boot_dir}/.git/"; then
    rm -rf "${boot_dir}/"
    git clone 'git@github.com:asakatida/boot.git' "${boot_dir}"
    "${boot_dir}/boot.sh"
    exit
  fi

  git clone 'git@github.com:asakatida/usr-bin.git' "${bin_dir}/"
fi

"${bin_dir}/tools/boot.sh"
