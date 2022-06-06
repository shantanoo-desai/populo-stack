# Populo Stack Compose Generator

This directory has all the necessary Compose files as individual `services` which can be
combined to generated a _main_ `docker-compose.yml` file in the root directory.

## Makefile

This directory contains a `Makefile` that is used to generate a `docker-compose.yml` in the root
directory as well as control the stack

```
Usage: make <target> where target is:
```

### gen-compose
Generates a Compose file with only selected services
```
gen-compose [service]

[service]:
    chronograf
    grafana
    influxdb
    mosquitto
    node-red
    portainer
    telegraf
    traefik
```
example usage:

```
make gen-compose chronograf influxdb telegraf
```

will produce a `docker-compose.yml` file in the root directory with `chronograf`, `influxdb`, `telegraf`

### gen-full-stack
Generate a Compose file will all services

example usage:

```
make gen-full-stack
```

will produce a `docker-compose.yml` file in the root directory with all the listed services in this directory

### gen-validate

Validate whether the generated Compose file is valid or not

example usage:

```
make gen-validate
```

will validate whether the `docker-compose.yml` file is valid or not

### logs

will provide logs for the dedicated service

```
logs [service]

[services]:
    chronograf
    grafana
    influxdb
    mosquitto
    node-red
    portainer
    telegraf
    traefik
```
example usage:

```
make logs traefik
```

### stack-down

Bring all the services down

example usage:

```
make stack-down
```

### stack-up

Bring the services up

example usage:

```
make stack-up
```

### teardown

will do the following:

- Bring the stack down
- __Purge all the volumes__
- __Remove the `docker-compose.yml` file__

example usage:

```
make teardown
```