FROM alpine

RUN set -x \
  && apk add --update --no-cache ca-certificates

COPY home.html /usr/bin/home.html
COPY hello-websocket /usr/bin/hello-websocket

ENTRYPOINT ["hello-websocket"]
