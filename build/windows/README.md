# Using Ubuntu

- Install docker

```sh
docker run -t -i --rm -v `pwd`:/io ubuntu:focal bash -c "apt-get clean && apt-get update >/dev/null && apt-get install -y curl >/dev/null && curl -sSL 'https://raw.githubusercontent.com/voltronic-inverter/binaries/master/build/windows/ubuntu_docker_build.sh' | bash"
```

[Look at it go](https://youtu.be/mew8AtH5wvU?t=14)