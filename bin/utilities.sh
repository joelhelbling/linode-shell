#!/bin/bash

source "./.env"

if [ -z ${SUMMARY_PATH+x} ]; then
  cat <<EOF
This script needs to know where to write a summary after
the process completes.  Please populate the variable
SUMMARY_PATH (note, you can put it in the .env file).
EOF
  exit 1
fi

JQ_BIN=`which jq`
if [ "$JQ_BIN" == "" ]; then
  echo "This script depends on jq"
  exit 1
fi

LINODE_BIN=`which linode-cli`
if [ "$LINODE_BIN" == "" ]; then
  echo "This script depends on linode-cli.  Please install it."
  exit 1
fi
LINODE_BIN="$LINODE_BIN --suppress-warnings"

UDF_JSON=./config/udf.json
if [ ! -f "$UDF_JSON" ]; then
  cat <<EOF
You need to create a json file at $UDF_JSON
You can begin by making a copy of config/udf.example.json
EOF
  exit 1
fi

function get_image_from_distribution() {
  distribution="$@"
  if [ -z ${IMAGE_JSON+x} ]; then
    IMAGE_JSON="`$LINODE_BIN images list --label="$distribution" --json | $JQ_BIN .[0]`"
  fi
  echo $IMAGE_JSON
}

function image_id_from_distribution() {
  distribution="$@"
  echo "`get_image_from_distribution "$distribution" | $JQ_BIN -r .id`"
}

function get_linode_from_label() {
  label=$1
  if [ -z ${LINODE_JSON+x} ]; then
    LINODE_JSON="`$LINODE_BIN linodes list --label=$label --json | $JQ_BIN .[0]`"
  fi
  echo $LINODE_JSON
}

function linode_id_from_label() {
  label=$1
  echo "`get_linode_from_label $label | $JQ_BIN -r .id`"
}

function ip_address_from_label() {
  label=$1
  echo "`get_linode_from_label $label | $JQ_BIN -r .ipv4[0]`"
}

function get_stackscript_from_name() {
  name=$1
  if [ -z ${STACKSCRIPT_JSON+x} ]; then
    STACKSCRIPT_JSON="`$LINODE_BIN stackscripts list --is_public=false --label=linode_initial_setup --json | $JQ_BIN .[0]`" 
  fi
  echo $STACKSCRIPT_JSON
}

function stackscript_id_from_name() {
  name=$1
  echo "`get_stackscript_from_name $name | $JQ_BIN .id`"
}

function generate_password() {
  echo "`openssl rand -base64 32 | tr -dc a-zA-Z0-9`"
}

function config_json() {
  if [ -z ${CONFIG_JSON+x} ]; then
    CONFIG_JSON="`$JQ_BIN . $UDF_JSON`"
  fi
  echo $CONFIG_JSON | jq .
}

function set_hostname() {
  hostname=$1
  CONFIG_JSON=`config_json | $JQ_BIN "setpath([\"server_hostname\"]; \"$hostname\")"`
}

function set_password() {
  password=$1
  CONFIG_JSON=`config_json | $JQ_BIN "setpath([\"password\"]; \"$password\")"`
}

function config_json_min() {
  echo `config_json | $JQ_BIN -c .`
}
