# Populo Stack

A completely customizable, pre-configured [Compose][1] Stack with some of the most Popular Containers.

## Containers

| Name           | Version            | Purpose                 |
|:--------------:|:------------------:|:------------------------| 
| __Chronograf__ | `1.9-alpine`       | Management of TSDB      |
| __Grafana__    | `8.5.4`            | Dashboard Tool          |
| __InfluxDB__   | `1.8.10-alpine`    | TSDB (data storage)     |
| __Mosquitto__  | `2.0.14`           | MQTT Message Broker     | 
| __Node-RED__   | `2.2.2-12-minimal` | Flow-Programming        |
| __Portainer__  | `2.13.1-alpine`    | Container Management    |
| __Telegraf__   | `1.22.4-alpine`    | Metric Collection Agent |
| __Traefik__    | `v2.7.0`           | Reverse-Proxy           |

## Design Rationale

1. use Multiple Compose files to make _dynamically configured_ `docker-compose.yml` files
2. avoid writing large `docker-compose.yml` files, rather control each Compose Service in its respective file
3. split the configuration based on each Compose Service for better control
4. Improve usability by providing a simple CLI, TUI, Web-UI

### Usability: CLI

Usage of `make` for following purposes:

- [x] creation of `docker-compose.yml` only for selected / all Compose Services
- [x] bringing the Compose Stack Up / Stack Down
- [x] cleaning up Volumes and removing `docker-compose.yml`
- [x] validating the generated `docker-compose.yml`

### Usability: TUI

Usage of `whiptail` for following purposes:

- [x] selection of Compose Services via a Terminal UI
- [x] generate `docker-compose.yml` only for selected Compose Services
- [x] bring the Stack Up for the generated `docker-compose.yml` file
- [x] set Default Credentials for Services (environment variables)

### Usability: Web-UI

Usage of `portainer` UI for Stack Management


[1]: https://docs.docker.com/compose/