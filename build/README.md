### Windows

```sh
docker run -t -i --rm -v `pwd`:/io ubuntu:focal bash -c "apt-get clean && apt-get update && apt-get install -y curl >/dev/null && curl -sSL 'https://raw.githubusercontent.com/voltronic-inverter/binaries/master/build/windows/ubuntu_docker_build.sh' | bash"
```

### Linux i686
```sh
docker run -t -i --rm -v `pwd`:/io phusion/holy-build-box-32:latest linux32 bash -c "curl -sSL 'https://raw.githubusercontent.com/voltronic-inverter/binaries/master/build/linux/holy_build_box.sh' | linux32 bash"
```

### Linux amd64
```sh
docker run -t -i --rm -v `pwd`:/io phusion/holy-build-box-64:latest bash -c "curl -sSL 'https://raw.githubusercontent.com/voltronic-inverter/binaries/master/build/linux/holy_build_box.sh' | bash"
```

### Linux arm-gnueabi
```sh
docker run -t -i --rm -v `pwd`:/io ubuntu:precise bash -c "apt-get clean && apt-get update && apt-get install -y curl >/dev/null && curl -sSL 'https://raw.githubusercontent.com/voltronic-inverter/binaries/master/build/linux/ubuntu_arm_build.sh' | bash"
```
