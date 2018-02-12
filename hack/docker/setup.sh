#!/bin/bash
set -eou pipefail

GOPATH=$(go env GOPATH)
SRC=$GOPATH/src
BIN=$GOPATH/bin
ROOT=$GOPATH
REPO_ROOT=$GOPATH/src/github.com/appscode/hello-websocket

source "$REPO_ROOT/hack/libbuild/common/lib.sh"
source "$REPO_ROOT/hack/libbuild/common/public_image.sh"

APPSCODE_ENV=${APPSCODE_ENV:-dev}
IMG=hello-websocket

DIST=$GOPATH/src/github.com/appscode/hello-websocket/dist
mkdir -p $DIST
if [ -f "$DIST/.tag" ]; then
	export $(cat $DIST/.tag | xargs)
fi

clean() {
    pushd $GOPATH/src/github.com/appscode/hello-websocket/hack/docker
    rm hello Dockerfile
    popd
}

build_binary() {
    pushd $GOPATH/src/github.com/appscode/hello-websocket
    # ./hack/builddeps.sh
    ./hack/make.py build
    detect_tag $DIST/.tag
    popd
}

build_docker() {
    pushd $GOPATH/src/github.com/appscode/hello-websocket/hack/docker
    cp $DIST/hello-websocket/hello-websocket-alpine-amd64 hello-websocket
    cp $GOPATH/src/github.com/appscode/hello-websocket/home.html home.html
    chmod 755 hello-websocket

    cat >Dockerfile <<EOL
FROM alpine

RUN set -x \
  && apk add --update --no-cache ca-certificates

COPY home.html /home.html
COPY hello-websocket /usr/bin/hello-websocket

USER nobody:nobody
ENTRYPOINT ["hello-websocket"]
EOL
    local cmd="docker build -t appscode/$IMG:$TAG ."
    echo $cmd; $cmd

    rm hello-websocket home.html Dockerfile
    popd
}

build() {
    build_binary
    build_docker
}

docker_push() {
    if [ "$APPSCODE_ENV" = "prod" ]; then
        echo "Nothing to do in prod env. Are you trying to 'release' binaries to prod?"
        exit 0
    fi
    if [ "$TAG_STRATEGY" = "git_tag" ]; then
        echo "Are you trying to 'release' binaries to prod?"
        exit 1
    fi
    hub_canary
}

docker_release() {
    if [ "$APPSCODE_ENV" != "prod" ]; then
        echo "'release' only works in PROD env."
        exit 1
    fi
    if [ "$TAG_STRATEGY" != "git_tag" ]; then
        echo "'apply_tag' to release binaries and/or docker images."
        exit 1
    fi
    hub_up
}

source_repo $@
