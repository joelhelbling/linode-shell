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

function image_list() {
  $LINODE_BIN images list --json \
  | $JQ_BIN -c 'map(.label)' \
  | sed 's/[][]//g' \
  | sed 's/,/\n/g' \
  | column
}

function get_image_from_label() {
  label="$@"
  if [ -z ${IMAGE_JSON+x} ]; then
    IMAGE_JSON="`$LINODE_BIN images list --label="$label" --json | $JQ_BIN .[0]`"
  fi
  echo $IMAGE_JSON
}

function image_id_from_label() {
  label="$@"
  echo "`get_image_from_label "$label" | $JQ_BIN -r .id`"
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
    STACKSCRIPT_JSON="`$LINODE_BIN stackscripts list --is_public=false --label=$name --json | $JQ_BIN .[0]`"
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

function deploy_parameters() {
  if [ -z ${DEPLOY_PARAMS} ]; then
    DEPLOY_PARAMS="`$DEPLOYMENTS_BIN $PATTERN`"
  fi
  echo $DEPLOY_PARAMS
}

function config_json() {
  if [ -z ${CONFIG_JSON+x} ]; then
    CONFIG_JSON="`deploy_parameters | $JQ_BIN '{gist_id,github_user,server_hostname,timezone,username}'`"
  fi
  echo $CONFIG_JSON | $JQ_BIN .
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

function result_json() {
  if [ -z ${RESULT_JSON+x} ]; then
    RESULT_JSON="{}"
  fi
  echo "`echo $RESULT_JSON | $JQ_BIN .`"
}

function set_result_json() {
  key=$1
  value=$2
  RESULT_JSON=`result_json | $JQ_BIN "setpath([\"$key\"]; \"$value\")"`
}

function set_result_json_bare() {
  key=$1
  value=$2
  RESULT_JSON=`result_json | $JQ_BIN "setpath([\"$key\"]; $value)"`
}