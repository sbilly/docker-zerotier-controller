# docker-zerotier-controller

Dockernized ZeroTierOne controller with zero-ui web interface. [中文讨论](https://v2ex.com/t/799623)

## Customize ZeroTierOne's controller planets

Modify `patch/planets.json` as you needed, then build the docker image. I've put the `patch/planet.public` and `patch/planet.private` files in this repo.

```json
{
  "planets": [
    {
      "Location": "Beijing", // Where this planet located
      "Identity": "a4de2130c2:0:ab5257bb05cd2fb8044fe26483f6d27b57124ca7b350fb3e0f07d405c68c4416094dbc836bf62ed483072501aa3384dff3c74ac50050c1bfbb1dc657001ef6a1", // The planet's public key, ex: identity.public
      "Endpoints": ["127.0.0.1/9993"] // The list of endpoints in 'ip/port' format. IPv6 is supportted
    }
  ]
}
```

## Build

```bash
docker build --force-rm . -t monteops/zerotier-controller:latest
```

## Run

### Controller

```bash
# Run with default settings
docker run --rm -ti -p 4000:4000 -p 9993:9993 -p 9993:9993/udp monteops/zerotier-controller:latest

# Run with custom envirments settings
docker run --rm -ti -e ZU_SECURE_HEADERS=false -e ZU_CONTROLLER_ENDPOINT=http://127.0.0.1:9993/ -e ZU_DEFAULT_USERNAME=admin -e ZU_DEFAULT_PASSWORD=zero-ui -p 4000:4000 -p 9993:9993 -p 9993:9993/udp monteops/zerotier-controller:latest

# Run with docker volumes
docker run --rm -ti -v `pwd`/config/identity.public:/app/config/identity.public -v `pwd`/config/identity.secret:/app/config/identity.secret -v `pwd`/config/authtoken.secret:/app/config/authtoken.secret -p 3000:3000 -p 4000:4000 -p 9993:9993 -p 9993:9993/udp monteops/zerotier-controller:latest
```

### Peer

Download `planet` from controller WEB interface to peer configuration directory. For example, `/var/lib/zerotier-one/planet`, Then start `zerotier-one`.

```bash
# Download planet
wget http://[IP_OF_CONTROLLER]:[PORT_OF_CONTROLLER]/app/static/planet -O /var/lib/zerotier-one/planet

# Start ZeroTierOne
zerotier-one /var/lib/zerotier-one
```

## Environment Variables

- The default username/password (`admin`/`zero-ui`) is defined by `ZU_DEFAULT_USERNAME` and `ZU_DEFAULT_PASSWORD`.
- The environment variable `ZT_PRIMARY_PORT` is ZeroTierOne's `primaryPort` in `local.conf`.
- Please check [zero-ui](https://github.com/dec0dOS/zero-ui/blob/main/README.md) for other environment variables.

## Files in Docker Image

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
- `ZeroTierOne`: The binaries of ZeroTierOne, such as `zerotier-*`, `mkworld`.

## FAQ

- **What's the difference from the official docker image of [zero-ui](https://github.com/dec0dOS/zero-ui)/[ztncui](https://github.com/key-networks/ztncui)**

  The offical docker images of [zero-ui](https://github.com/dec0dOS/zero-ui) and [ztncui](https://github.com/key-networks/ztncui) are controller‘s interface. And we provide full operational functions of planet/controller/controller-ui of ZeroTier.


## Change Log
- 20220215 - Update software versions and Readme
- 20211206 - Add FAQ section.
- 20210904 - Update peer's instructions.
- 20210902 - First Release.
