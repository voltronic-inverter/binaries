### Process

- Install docker

### i686
```sh
docker run -t -i --rm -v `pwd`:/io phusion/holy-build-box-32:latest linux32 bash -c "curl 'https://raw.githubusercontent.com/voltronic-inverter/binaries/master/build/linux/holy_build_box.sh' | linux32 bash"
```

### x86-64
```sh
docker run -t -i --rm -v `pwd`:/io phusion/holy-build-box-64:latest bash -c "curl 'https://raw.githubusercontent.com/voltronic-inverter/binaries/master/build/linux/holy_build_box.sh' | bash"
```

[Look at it go](https://youtu.be/mew8AtH5wvU?t=14)