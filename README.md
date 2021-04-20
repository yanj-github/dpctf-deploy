# DPCTF test runner docker image

This repository contains configuration files to build a docker image and run 
it in a container with proper configuration.

## Requirements

- Docker v20
- docker-compose v1.29
- **Windows** and **Linux** require root permissions for the provided commands. 
  - [Run docker without root on Linux](https://docs.docker.com/engine/install/linux-postinstall/#manage-docker-as-a-non-root-user)
  - [Run docker without admin on Windows](https://docs.docker.com/engine/install/linux-postinstall/#manage-docker-as-a-non-root-user)

## Create Image

To build the image, simply run

```shell
./build.sh <commit-id/branch/tag> <image-version> [<tests-revision> [<runner-revision>]]
```

In this command **commit-id/branch/tag** specifies what code base to use 
from the [DPCTF Test Runner repository](https://github.com/cta-wave/dpctf-test-runner) in the created 
image. As indicated, this can be a commit id, a branch name or a tag. 
**image-version** specifies the version string the created docker image is 
tagged with. This allows to have multiple image with different versions.
The build script will name the image `dpctf:<image-version>`.  
**tests-revision** is an optional parameter used to circumvent caching of used 
dpctf-tests when building the image. The provided value has no semantics, 
therefore, when rebuilding the image for different dpctf-tests it is 
sufficient to provide some value that differs from previous builds.  
**runner-revision** is an optional parameter used similarly to the 
tests-revision parameter, but in regards to the used dpctf runner version. 
This is especially useful when using branch names, which keep their names 
while the underlying code may change.

For example:

```shell
./build.sh master latest
```

To rebuild the image using the cache but retrigger the download of the tests, 
use the tests revision parameter:

```shell
./build.sh master latest 1
```

To rebuild the image using the cache but retrigger the download of the test 
runner, use the runner revision parameter:

```shell
./build.sh master latest 1 1
```

This will create a docker image for the latest code base on the master branch 
and sets the version tag to "latest". The resulting image will have the name
`dpctf:latest`.

## Running the created image in a container

To run the created image in a properly configured container, set the desired image version:

`docker-compose.yml`
```yaml
services:
  dpctf:
    container_name: dpctf
    image: dpctf:latest
```

**container_name** defines the name of the container, so we can later 
reference it when using docker commands specific to containers like start, 
stop, view logs and so on. **image** specifies what image to use to create the 
container. In this example, we use the version string of the example from the 
section "Create Image". The file contains further configurations, but for now 
this should suffice.

Every directory mapped into the container has to have its owner set to user id
1000 in order for the test runner to perform read and write actions.

To then start the container run the following command:

```shell
docker-compose up -d
```

This will use the configuration in the `docker-compose.yml` to create a new
container and run it in the background.

The test runner can be configured using the `config.json`. For more details 
see the [docs](https://github.com/cta-wave/dpctf-test-runner/blob/master/tools/wave/docs/config.md).

All test results will be stored in the `results` directory.

## Mapping new content into the container

It may be useful to be able to use custom content with the test runner. This requires modification of the `docker-compose.yml` for any directory or file that should be mapped into the container.

Inside the `docker-compose.yml` under `volumes`, add a new line per file or directory to map:

```yaml
    volumes:
      - <src_host_path>:<dest_container_path>
```

The `src_host_path` can be an absolute or relative path. The `dest_container_path` should be `/home/ubuntu/DPCTF/<dest_name>`, to make it available for serving from the test runners web server.

For example, to map a new group of tests named 'test-group' and a custom `test-config.json`:

```
ls

docker-compose.yml
test-group
test-config.json
```

```yaml
    volumes:
      - ./test-group:/home/ubuntu/DPCTF/test-group
      - ./test-config.json:/home/ubuntu/DPCTF/test-config.json
```

Then restart the container using docker-compose command:

```
docker-compose up -d
```

Files are now accessible under the relative path to the test runner directory:

Test files inside 'test-group':
```
http://web-platform.test:8000/test-group/
```

`test-config.json`:
```
http://web-platform.test:8000/test-config.json
```

## Controlling the running container

You can control the running container using a set of commands, which receive 
the name of the container you want to perform the action on.

Start container

```shell
docker start <container_name>
```

Stop container

```shell
docker stop <container_name>
```

View logs

```shell
docker logs <container_name>
```

In our case, **container_name** is `dpctf`, unless it was changed in the `docker-compose.yml`.

## Running tests

In general, to access the test runners landing page, it can be accessed under the following URL:
```
http://<host-domain/ip>:<port>/_wave/index.html
```

- **host-domain/ip**: The domain or IP of the machine that hosts the DPCTF 
test runner. To access the host machine by its IP address, add the `host_override` 
parameter to the config.json. For more details see 
[the docs](https://github.com/cta-wave/dpctf-test-runner/blob/master/tools/wave/docs/config.md#211-host-override)
- **port**: The port number the DPCTF test runner is runner on

Please also see the DPCTF section in the DPCTF Test Runner [Readme file](https://github.com/cta-wave/dpctf-test-runner#dpctf-info).
For further information on how to configure sessions and general usage see [the documentation](https://github.com/cta-wave/dpctf-test-runner/blob/master/tools/wave/docs/usage/usage.md) (please make sure that dpctf is selected when configuring a new session).

Additionally, it is possible to run tests using the [REST API](https://github.com/cta-wave/dpctf-test-runner/blob/master/tools/wave/docs/rest-api/README.md).

### Run on host machine

![Single Machine Setup](./same-machine-setup.jpg)

The most simple use case is to execute the test on the same machine as the 
DPCTF test runner is running on. Run the docker container and access the 
landing page to execute tests and configure the session. As everything runs on 
the same machine, the host can be localhost. Use the "Configure Session" 
button on the landing page to configure and start the session.

### Run on separate DUT (TV, Mobile, etc.)

![PC-DUT Setup](./pc-dut-setup.jpg)

Another common use case is to have a separate device under test, like a TV or 
mobile device, to run the tests on. Run the docker container on a PC and 
configure the [`host_override`](https://github.com/cta-wave/dpctf-test-runner/blob/master/tools/wave/docs/config.md#211-host-override)
 parameter to equal the IP of the test runners machine is reachable by. Then 
access the landing page on the DUT using this IP. On the PC open the URL 
`/_wave/configuration.html` and enter the session token displayed on the 
landing page to configure and start the session.

### Run on separate DUT using companion device

![PC-DUT-Companion Setup](./pc-dut-companion-setup.jpg)

A companion device may be used to configure and manage a test session. In this 
setup, the test runner is hosted on one device, whereas another device is used 
to configure and monitor the test session that runs on the DUT. Run the docker 
container on a machine, open the landing page on the DUT and scan the QR code 
using a mobile device. On the mobile device, configure the session as needed 
and start the test execution.
