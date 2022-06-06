#!/bin/env bash

WHIPTAIL=$(which whiptail)

if [ -z $WHIPTAIL ]
then
    echo "This script requires whiptail to render the TUI."
    exit 1
fi

MAKE=$(which make)
ENVSUBST=$(which envsubst)
HTPASSWD=$(which htpasswd)

declare -a SELECTED_SERVICES=()

LINES=$(tput lines)
COLUMNS=$(tput cols)

POPULO_CONF_DIR=./conf
SERVICES_DIR=./services

declare -A availableServices=(
    [chronograf]="Chronograf UI for InfluxDB"
    [grafana]="Grafana Dashboard"
    [influxdb]="InfluxDB v1.x TSDB"
    [mosquitto]="Mosquitto MQTT Broker"
    [node-red]="Node-RED Flow UI"
    [portainer]="Portainer Container Mgmt"
    [telegraf]="Telegraf Aggregation Agent"
)

function askGenerateFullStack {
    local message="Generate a Compose file for the  complete Populo Stack (all services)?"

    $WHIPTAIL --title "Generate Full Stack with all Services" \
            --no-button "No (Create Custom Stack)" \
            --yesno "$message" $LINES $COLUMNS 

}

function askGenerateCustomStack {
    local message="Generate a Compose file with only selected services\n
                Press <SPACEBAR> to Select \n
                Press <Enter> to Skip
                "
    local arglist=()
    
    # Generate a String for Whiptail Checkboxes
     # FORMAT: "<INDEX> <DESCRIPTION> <OFF>"
    for index in "${!availableServices[@]}";
    do
        # Default all Services are NOT-Selected (OFF)
        arglist+=("$index" "${availableServices[$index]}" "OFF")
    done
    readarray -t SELECTED_SERVICES< <("$WHIPTAIL" --title "Available Services within Populo" \
                --notags --separate-output \
                --ok-button Next \
                --nocancel \
                --checklist "$message" $LINES $COLUMNS $(( LINES - 12 )) \
                -- "${arglist[@]}" \
                3>&1 1>&2 2>&3)
}


function setInfluxDBCredentials {
    local message="Enter a Password and select Ok, select Cancel to set default password"

    # 1. Set the InfluxDB Admin Password
    local INFLUXDB_ADMIN_PWD=$($WHIPTAIL --passwordbox "$message"  \
        $LINES $COLUMNS \
        --title "InfluxDB Admin Creds" \
        3>&1 1>&2 2>&3)

    # If Cancel pressed, set Default Password
    export INFLUXDB_ADMIN_PWD=${INFLUXDB_ADMIN_PWD:-P0puloStack}

    # 2. Set the InfluxDB User Password
    local INFLUXDB_USER_PWD=$($WHIPTAIL --passwordbox "$message"  \
        $LINES $COLUMNS \
        --title "InfluxDB User Creds" \
        3>&1 1>&2 2>&3)

    # If Cancel pressed, set Default Password
    export INFLUXDB_USER_PWD=${INFLUXDB_USER_PWD:-P0puloStack}

    # 3. Set InfluxDB Read User Password
    local INFLUXDB_READ_USER_PWD=$($WHIPTAIL --passwordbox "$message"  \
        $LINES $COLUMNS \
        --title "InfluxDB Read User Creds" \
        3>&1 1>&2 2>&3)
    
    # If Cancel pressed, set Default Password
    export INFLUXDB_READ_USER_PWD=${INFLUXDB_READ_USER_PWD:-P0puloStack}

    # 4. Set InfluxDB Write User Password
    local INFLUXDB_WRITE_USER_PWD=$($WHIPTAIL --passwordbox "$message"  \
        $LINES $COLUMNS \
        --title "InfluxDB Write User Creds" \
        3>&1 1>&2 2>&3)
    
    # If Cancel Pressed, set Default Password
    export INFLUXDB_WRITE_USER_PWD=${INFLUXDB_WRITE_USER_PWD:-P0puloStack}

    # Set the passwords using the template File
    touch $POPULO_CONF_DIR/influxdb/influxdb.env $POPULO_CONF_DIR/chronograf/chronograf.env $POPULO_CONF_DIR/telegraf/telegraf.env

    $ENVSUBST '${INFLUXDB_ADMIN_PWD},${INFLUXDB_USER_PWD},${INFLUXDB_READ_USER_PWD},${INFLUXDB_WRITE_USER_PWD}' \
     < $POPULO_CONF_DIR/influxdb/influxdb.tpl.env > $POPULO_CONF_DIR/influxdb/influxdb.env
    
    # Set the Admin password for Chronograf
    $ENVSUBST '${INFLUXDB_ADMIN_PWD}' < $POPULO_CONF_DIR/chronograf/chronograf.tpl.env > $POPULO_CONF_DIR/chronograf/chronograf.env

    # Set the Write password for Chronograf
    $ENVSUBST '${INFLUXDB_WRITE_USER_PWD}' < $POPULO_CONF_DIR/telegraf/telegraf.tpl.env > $POPULO_CONF_DIR/telegraf/telegraf.env

    unset INFLUXDB_ADMIN_PWD INFLUXDB_USER_PWD INFLUXDB_READ_USER_PWD INFLUXDB_WRITE_USER_PWD
}


function setGrafanaCredentials {
    local message="Enter a Password and select Ok, select Cancel to set default password"

    # 1. Set the InfluxDB Admin Password
    local GRAFANA_ADMIN_PWD=$($WHIPTAIL --passwordbox "$message"  \
        $LINES $COLUMNS \
        --title "Grafana Admin Creds" \
        3>&1 1>&2 2>&3)

    # If Cancel pressed, set Default Password
    export GRAFANA_ADMIN_PWD=${GRAFANA_ADMIN_PWD:-P0puloStack}

    # Set the Admin password for Chronograf
    touch $POPULO_CONF_DIR/grafana/grafana.env

    $ENVSUBST '${GRAFANA_ADMIN_PWD}' < $POPULO_CONF_DIR/grafana/grafana.tpl.env > $POPULO_CONF_DIR/grafana/grafana.env
    unset GRAFANA_ADMIN_PWD
}

function setNodeRedCredentials {
    local message="Enter a Password and select Ok, select Cancel to set default password"

    # 1. Set the InfluxDB Admin Password
    local NODERED_ADMIN_AUTH=$($WHIPTAIL --passwordbox "$message"  \
        $LINES $COLUMNS \
        --title "Node-RED Admin Creds" \
        3>&1 1>&2 2>&3)


    touch /tmp/populo_node-red
    echo $NODERED_ADMIN_AUTH > /tmp/populo_node-red
    # Encrypt Node-RED plaintext password in `bcrypt` format with 8 rounds of Cost
    NODERED_ADMIN_AUTH=$($HTPASSWD -nb -B -C 8 admin ${NODERED_ADMIN_AUTH:-P0puloStack})

    export NODERED_ADMIN_AUTH=$NODERED_ADMIN_AUTH

    # Set the Admin password for Chronograf
    touch $POPULO_CONF_DIR/node-red/node-red.env

    $ENVSUBST '${NODERED_ADMIN_AUTH}' < $POPULO_CONF_DIR/node-red/node-red.tpl.env > $POPULO_CONF_DIR/node-red/node-red.env
    unset NODERED_ADMIN_AUTH
}

function setPortainerCredentials {

    local message="Enter a Password and select Ok, select Cancel to set default password"

    # 1. Set the Portainer Admin Password
    PORTAINER_ADMIN_PWD=$($WHIPTAIL --passwordbox "$message"  \
        $LINES $COLUMNS \
        --title "Portainer Admin Creds" \
        3>&1 1>&2 2>&3)
    
    export PORTAINER_ADMIN_PWD=${PORTAINER_ADMIN_PWD:-P0puloStack}

    echo $PORTAINER_ADMIN_PWD > $POPULO_CONF_DIR/portainer/secrets/portainer_admin_password

    unset PORTAINER_ADMIN_PWD 
}

function setTraefikCredentials {
    local message="Enter a Password and select Ok, select Cancel to set default password"

    # 1. Set the InfluxDB Admin Password
    local TRAEFIK_ADMIN_AUTH=$($WHIPTAIL --passwordbox "$message"  \
        $LINES $COLUMNS \
        --title "Traefik Admin Creds" \
        3>&1 1>&2 2>&3)


    touch /tmp/populo_traefik
    echo $TRAEFIK_ADMIN_AUTH > /tmp/populo_traefik

    # Encrypt Node-RED plaintext password in `bcrypt` format with 8 rounds of Cost
    TRAEFIK_ADMIN_AUTH=$($HTPASSWD -nb -B -C 8 admin ${TRAEFIK_ADMIN_AUTH:-P0puloStack})

    export TRAEFIK_ADMIN_AUTH=$TRAEFIK_ADMIN_AUTH

    # Set the Admin password for Chronograf
    touch $POPULO_CONF_DIR/traefik/users

    $ENVSUBST '${TRAEFIK_ADMIN_AUTH}' < $POPULO_CONF_DIR/traefik/users.tpl > $POPULO_CONF_DIR/traefik/users
    unset TRAEFIK_ADMIN_AUTH
}

#Set 0: Set Authentication for Traefik Reverse-Proxy
setTraefikCredentials

# Step 1: Ask whether to generate the complete Populo Stack
if askGenerateFullStack; then
    # before generating the full stack ask user to set the credentials for
    # all services that require environment variables
    setGrafanaCredentials
    setInfluxDBCredentials
    setNodeRedCredentials
    setPortainerCredentials

    $MAKE -C $SERVICES_DIR gen-full-stack
else
    askGenerateCustomStack
    if [ -z "$SELECTED_SERVICES" ]; then
        echo "No Services were selected. Exiting..."
        exit 1
    else
        for service in "${SELECTED_SERVICES[@]}";
        do
          case "$service" in
            "influxdb")  echo "Setting Credentials for InfluxDB"; setInfluxDBCredentials;;
            "grafana")   echo "Setting Credentials for Grafana"; setGrafanaCredentials;;
            "node-red")  echo "Setting Credentials for node-RED"; setNodeRedCredentials;;
            "portainer") echo "Setting Credential for Portainer"; setPortainerCredentials;;
            *)  echo "Error; unknown option: $SELECTED_SERVICES" >&2;;
          esac
        done
        $MAKE -C ${SERVICES_DIR} gen-compose ${SELECTED_SERVICES[@]}
    fi
fi
