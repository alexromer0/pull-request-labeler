FROM alpine:3.10

RUN apk add --no-cache jq bash curl bc coreutils

ADD ./entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]