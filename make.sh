#!/bin/bash
set -xeuo pipefail

docker build -t appscode/hello-websocket:latest .
docker push appscode/hello-websocket:latest
