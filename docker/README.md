This directory contains files to support a containerized Docker version of the COVID-19 sarix model that can be run locally or via [AWS ECS](https://aws.amazon.com/ecs/). Following is information needed to set up and run the image.

# Environment variables

The app uses the helper scripts in https://github.com/reichlab/container-utils/, which require the following environment variables: `SLACK_API_TOKEN`, `CHANNEL_ID`; `GH_TOKEN`; `GIT_USER_NAME`, `GIT_USER_EMAIL`; `GIT_CREDENTIALS`. Please that repo for details. Note that it's easiest and safest to save these in a `*.env` file and then pass that file to `docker run`.

# `/data` dir

The app expects a volume (either a [local Docker one](https://docs.docker.com/storage/volumes/) or an [AWS EFS](https://aws.amazon.com/efs/) file system) to be mounted at `/data` and which contains this required GitHub repo:
- [this fork](https://github.com/reichlabmachine/covid19-forecast-hub) of https://github.com/reichlab/covid19-forecast-hub

How that volume is populated (i.e., running `git clone` calls) depends on whether you're running locally or on ECS:

## populate a local Docker volume

Launch a temporary container that mounts the Docker volume at `/data`. E.g.,

```bash
# create the empty volume
docker volume create data_volume

# (optional) explore the volume from the command line via a temp container
docker run --rm -it --name temp_container --mount type=volume,src=data_volume,target=/data ubuntu /bin/bash

# if you need git installed:
apt update ; apt install -y git
```

## populate an EFS volume

Launch a temporary [AWS EC2](https://aws.amazon.com/ec2/) instance that mounts the EFS file system at `/data`. See https://github.com/reichlab/container-utils/blob/main/docs/ecs.md for details.

# To build the image

```bash
cd "path-to-this-repo"
docker build --tag=sarix-covid:1.0 --file=docker/Dockerfile .
```

# To run the image locally

```bash
docker run --rm \
  --mount type=volume,src=data_volume,target=/data \
  --env-file /path-to-env-dir/.env \
  sarix-covid:1.0
```

# To run the image on AWS ECS

See https://github.com/reichlab/container-utils/blob/main/docs/ecs.md for details.

# To publish the image

> Note: Make sure the image you push for ECS use is built for the `amd64` architecture. This is important if you're running on an Apple Silicon Mac, which has a `arm64` architecture. Use `--platform=linux/amd64` for your `docker build` command.

```bash
docker login -u "reichlab" docker.io
docker tag sarix-covid:1.0 reichlab/sarix-covid:1.0
docker push reichlab/sarix-covid:1.0
```
