# ruby-template 🧰

[![test](https://github.com/GrantBirki/ruby-template/actions/workflows/test.yml/badge.svg)](https://github.com/GrantBirki/ruby-template/actions/workflows/test.yml)
[![lint](https://github.com/GrantBirki/ruby-template/actions/workflows/lint.yml/badge.svg)](https://github.com/GrantBirki/ruby-template/actions/workflows/lint.yml)
[![build](https://github.com/GrantBirki/ruby-template/actions/workflows/build.yml/badge.svg)](https://github.com/GrantBirki/ruby-template/actions/workflows/build.yml)

## Usage 💻

### Docker Builds

Build a Docker image:

```bash
script/docker-build
```

The result of this command will be a Docker image built with the name `ruby-template:latest`.

### Building Tarballs

To build a tarball of the application for deployment, run the following command:

```bash
script/tarball
```

This will build a docker container and run the `script/build-deploy-tarball` script inside the container. The result will be a tarball in the `tarballs/` directory at the root of the repository.

Tarballs are popular for atomic deployments where the deployment is a simple matter of extracting the tarball to the correct location on the target machine and running the new version of the application. Tarball deploys help to shift the complexity of the deployment process from the target machine to the build server (in this case, the CI server - Actions).
