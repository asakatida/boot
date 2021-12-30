FROM alpine

ARG GITHUB_TOKEN
ARG SSH_KEY
ARG SSH_KEY_TITLE

ADD ./boot.sh /tmp/boot.sh
RUN chmod 700 /tmp/boot.sh
RUN /tmp/boot.sh
