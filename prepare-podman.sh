#!/bin/bash

podman unshare rm -rf ./data/*
mkdir -p ./data/{redis,pg-backend,pg-sources,pg-notifications,zookeeper,kafka}
podman unshare chown -R 1001:1001 ./data/kafka ./data/zookeeper
