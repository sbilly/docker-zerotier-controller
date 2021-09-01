# docker-zerotier-controller

Dockernized ZeroTierOne Controller

## Build

```bash
docker build --force-rm . -t sbilly/zerotier-controller:latest
```

## Run

```bash
# Run with default settings
docker run --rm -ti -p 4000:4000 -p 9993:9993 -p 9993:9993/udp sbilly/zerotier-controller:latest

# Run with custom envirments settings
docker run --rm -ti -e ZU_SECURE_HEADERS=false -e ZU_CONTROLLER_ENDPOINT=http://127.0.0.1:9993/ -e ZU_DEFAULT_USERNAME=admin -e ZU_DEFAULT_PASSWORD=zero-ui -p 4000:4000 -p 3000:3000 -p 9993:9993 -p 9993:9993/udp sbilly/zerotier-controller:latest

# Run with docker volumes
docker run --rm -ti -v `pwd`/config/identity.public:/app/config/identity.public -v `pwd`/config/identity.secret:/app/config/identity.secret -v `pwd`/config/authtoken.secret:/app/config/authtoken.secret -p 3000:3000 -p 4000:4000 -p 9993:9993 -p 9993:9993/udp sbilly/zerotier-controller:latest
```

## Environment Variables

- The default username/password (`admin`/`zero-ui`) is defined by `ZU_DEFAULT_USERNAME` and `ZU_DEFAULT_PASSWORD`.
- The environment variable `ZT_PRIMARY_PORT` is ZeroTierOne's `primaryPort` in `local.conf`.
- Other environment variables please check [zero-ui](https://github.com/dec0dOS/zero-ui/blob/main/README.md)

## Files in docker image

```bash
/app/
├── config/
├── backend/
├── frontend/
└── ZeroTierOne/
```

- `config`: The configurations of ZeroTierOne, such as `identity.*`, `authtoken.secret`, etc.
- `backend`: zero-ui backend.
- `frontend`: The static files of zero-ui frontend.
- `ZeroTierOne`: The binaries of ZeroTierOne, such as `zerotier-c*`, `mkworld`.
