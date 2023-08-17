#!/bin/bash

podman unshare rm -rf ./data/*
mkdir -p ./data/{redis,pg-backend,pg-sources,pg-notifications,zookeeper,kafka}
podman unshare chown -R $(id -u):$(id -g) ./data/kafka ./data/zookeeper
