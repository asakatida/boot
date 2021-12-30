#!/bin/sh

export GITHUB_TOKEN='***REMOVED***'
export SSH_KEY_TITLE='alexis-alpine'
export SSH_KEY=''

docker build --build-arg GITHUB_TOKEN --build-arg SSH_KEY_TITLE .
