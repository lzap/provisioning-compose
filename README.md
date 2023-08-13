# Containerized provisioning

This repo helps rolling up the provisioning application, including frontend and all integrated services such as sources for development purpose, demo or testing with no extra setup. This repo uses [git-submodules](https://github.blog/2016-02-01-working-with-submodules/) for linking different services all-together as sub directories.

## Setup

```sh
$ git clone https://github.com/RHEnVision/provisioning-compose.git
$ git submodule init
$ git submodule update
```

After cloning, the folder structure should be:
```
   ├── provisioning-compose
   │   ├── backend
   │   ├── frontend
   │   ├── notifications
   │   ├── sources-api-go
   │   ├── image-builder-frontend   
   └── 
```

Before use, some images are currently from private quay.io repositories so make sure to login via `docker login quay.io` or `podman login quay.io`.

Copy all services env files - `*.example.env` -> `.env`, you can add or edit your custom variables.

```bash
$ cp backend.example.env backend.env
```

In first use, to run all services locally altogether, including seeding and migration:

```sh
$ COMPOSE_PROFILES=kafka,notifications,notifications-init,backend-dev,sources-dev,frontend-dev docker compose up
```

Alternatively, with podman, to start backend and sources:

```
pip3 install podman-compose
./prepare-podman.sh
podman-compose --profile sources --profile backend up
```

The first start may fail as the initialization of the database takes too long and some services may give up, perform "down" and then "up" again and it will work. If you encounter permission issues, [troubleshoot SELinux](https://www.redhat.com/sysadmin/container-permission-denied-errors).

To customize exposed ports, make a copy of `compose.example.env` file and run with `env-file` option:

```
podman-compose --env-file compose.example.env --profile kafka up
```

Make sure to use podman-compose 1.0.7 or newer for profiles feature, install development version if not available yet (as of Summer 2023).

### Seeding

To seed sources database, create configuration file first:

	cp sources_seed/sources.example.conf sources_seed/sources.conf

Edit it, we suggest to create the same account/org id as on stage so you can switch to stage later:

	export ACCOUNT_ID=1234
	export ORG_ID=9876
	export ARN_ROLE=arn:aws:iam::123456789:role/satellite-services-role
	export SUBSCRIPTION_ID=ffd0879a-3149-a750-a10f-8aaf77786ad3
	export PROJECT_ID=provisioning-7832643

When the compose is up, run:

	./sources_seed/seed.sh

### Profiles

A compose profile allows you to run a subset of containers. When no profile is given, 
the provisioning backend, postgres and redis will run by default.

Profiles:
- kafka: run kafka with zookeeper, register topics
- sources: run latest sources service image from quay
- sources-dev: run local sources with postgres db, on first use notice that you will need to run `/script/sources.seed.sh` for seeding your local sources data.
- backend: migrate and run the provisioning backend, with postgres and redis from the official image
- backend-dev: migrate and run the provisioning backend, with postgres and redis from git
- frontend-dev: run local provisioning frontend
- notifications: running local notification-backend service
- notifications-init: seeds the required provisioning data, required for the first notifications use.
- image-builder-frontend: run local frontend (federated mode) and local image-builder frontend


For example, in order to run local sources, kafka, local backend and frontend profiles, run

	COMPOSE_PROFILES=frontend-dev,backend-dev,kafka,sources-dev docker compose up 

 ### Notifications local setup
 See notifications [section](/notifications_seed/README.md)

### Image builder
[Image builder](https://github.com/RedHatInsights/image-builder-frontend) consumes provisioning application as a federated module, for adding the launch wizard component.
Following this dependency, a local dev environment containing both apps is required.
The profile `image-builder-frontend` runs provisioning in a static federated mode, and image-builder-frontend
in beta-stage, both with live-reload capabilities.

### Connecting to Kafka

Kafka advertises the connection (hostname and port) during session negotiation, therefore, it is necessary to change host resolution configuration in a way that "kafka" hostname resolves to the host that is hosting kafka containers. Typically:

	cat /etc/hosts
	127.0.0.1 kafka

Change it accordingly if you running podman on a remote machine. The symptoms are that application (backend) is unable to connect to `kafka:9092` or `kafka:29092`.


### Live reloading for dev

The backend container uses [CompileDaemon](github.com/githubnemo/CompileDaemon) for live reloading, it watches for changes, re-build and run the server when a change occurs. The frontend container uses webpack dev server hot reloading.

### Rootless containers

Some data is stored under `./data` folder. When you use podman as non-root, you might get into issue of not being able to delete the files. To fix this:

	podman unshare rm -rf data/*

Some containers run the service as root, for example:

	podman run --rm docker.io/redis:latest id
	uid=0(root) gid=0(root) groups=0(root)

Root user in rootless podman is automatically mapped to your user. However, if the container is built in a way that it uses a regular user, this will not work. Example:

	podman run --rm quay.io/strimzi/kafka:latest-kafka-3.4.0 id
	uid=1001(kafka) gid=0(root) groups=0(root)

In this case, directory needs to be created with the correct permission:

	podman unshare chown -R 1001:1001 ./data/kafka ./data/zookeeper

After podman starts, it will change the owner to 165536 + 1001.

Special thanks to Robb Manes for his help with understanding of how rootless podman works. Some additional links:

* https://www.redhat.com/sysadmin/container-permission-denied-errors
* https://www.redhat.com/sysadmin/files-devices-podman
* https://www.redhat.com/sysadmin/debug-rootless-podman-mounted-volumes
* https://access.redhat.com/articles/5946151
