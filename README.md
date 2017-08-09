# simp build
build the simpz
just the modules for now

## reqs

* docker

## steps

* build docker image: `docker build -t simp/build .`
* run script in docker: `docker run --rm -v "$PWD":/usr/src/app -w /usr/src/app simp/build ruby ./build.rb 6.0.0-0`
* look in `rpms/`
