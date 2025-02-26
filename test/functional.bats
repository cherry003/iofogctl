#!/usr/bin/env bash

# Required environment variables
# NAMESPACE
# KUBE_CONFIG
# AGENT_LIST
# VANILLA_CONTROLLER
# KEY_FILE
# PACKAGE_CLOUD_TOKEN
# CONTROLLER_IMAGE
# CONNECTOR_IMAGE
# SCHEDULER_IMAGE
# OPERATOR_IMAGE
# KUBELET_IMAGE
# VANILLA_VERSION

. test/functions.bash

NS="$NAMESPACE"
NAME="func_test"

function initAgents(){
  USERS=()
  HOSTS=()
  PORTS=()
  AGENTS=($AGENT_LIST)
  for AGENT in "${AGENTS[@]}"; do
    local USER=$(echo "$AGENT" | sed "s|@.*||g")
    local HOST=$(echo "$AGENT" | sed "s|.*@||g")
    local PORT=$(echo "$AGENT" | cut -d':' -s -f2)
    local PORT="${PORT:-22}"

    USERS+=" "
    USERS+="$USER"
    HOSTS+=" "
    HOSTS+="$HOST"
    PORTS+=" "
    PORTS+="$PORT"
  done
  USERS=($USERS)
  HOSTS=($HOSTS)
  PORTS=($PORTS)
}

function initVanillaController(){
  VANILLA_USER=$(echo "$VANILLA_CONTROLLER" | sed "s|@.*||g")
  VANILLA_HOST=$(echo "$VANILLA_CONTROLLER" | sed "s|.*@||g")
  VANILLA_PORT=$(echo "$VANILLA_CONTROLLER" | cut -d':' -s -f2)
  VANILLA_PORT="${PORT:-22}"
}

function checkController() {
  [[ "$NAME" == $(iofogctl -q -n "$NS" get controllers | grep "$NAME" | awk '{print $1}') ]]
  [[ ! -z $(iofogctl -q -n "$NS" describe controller "$NAME" | grep "name: $NAME") ]]
}

function checkControllerNegative() {
  [[ "$NAME" != $(iofogctl -q -n "$NS" get controllers | grep "$NAME" | awk '{print $1}') ]]
}

function checkAgents() {
  for IDX in "${!AGENTS[@]}"; do
    local AGENT_NAME="${NAME}_$(((IDX++)))"
    [[ "$AGENT_NAME" == $(iofogctl -q -n "$NS" get agents | grep "$AGENT_NAME" | awk '{print $1}') ]]
    [[ ! -z $(iofogctl -q -n "$NS" describe agent "$AGENT_NAME" | grep "name: $AGENT_NAME") ]]
  done
}

function checkAgentsNegative() {
  for IDX in "${!AGENTS[@]}"; do
    local AGENT_NAME="${NAME}_$(((IDX++)))"
    [[ "$AGENT_NAME" != $(iofogctl -q -n "$NS" get agents | grep "$AGENT_NAME" | awk '{print $1}') ]]
  done
}

@test "Create namespace" {
  test iofogctl create namespace "$NS"
}

@test "Deploy controller" {
  test iofogctl -q -n "$NS" deploy controller "$NAME" --kube-config "$KUBE_CONFIG"
  checkController
}

@test "Get credentials" {
  export CONTROLLER_EMAIL=$(iofogctl -q -n "$NS" describe controller "$NAME" | grep email | sed "s|.*email: ||")
  export CONTROLLER_PASS=$(iofogctl -q -n "$NS" describe controller "$NAME" | grep password | sed "s|.*password: ||")
  export CONTROLLER_ENDPOINT=$(iofogctl -q -n "$NS" describe controller "$NAME" | grep endpoint | sed "s|.*endpoint: ||")
  [[ ! -z "$CONTROLLER_EMAIL" ]]
  [[ ! -z "$CONTROLLER_PASS" ]]
  [[ ! -z "$CONTROLLER_ENDPOINT" ]]
  echo "$CONTROLLER_EMAIL" > /tmp/email.txt
  echo "$CONTROLLER_PASS" > /tmp/pass.txt
  echo "$CONTROLLER_ENDPOINT" > /tmp/endpoint.txt
}


@test "Controller legacy commands after deploy" {
  sleep 15 # Sleep to avoid SSH tunnel bug from K8s
  test iofogctl -q -n "$NS" legacy controller "$NAME" iofog list
}

@test "Get Controller logs on K8s after deploy" {
  test iofogctl -q -n "$NS" logs controller "$NAME"
}

@test "Deploy agents" {
  initAgents
  for IDX in "${!AGENTS[@]}"; do
    local AGENT_NAME="${NAME}_${IDX}"
    test iofogctl -q -n "$NS" deploy agent "$AGENT_NAME" --user "${USERS[IDX]}" --host "${HOSTS[IDX]}" --key-file "$KEY_FILE" --port "${PORTS[IDX]}"
  done
  checkAgents
}

@test "Agent legacy commands" {
  for IDX in "${!AGENTS[@]}"; do
    local AGENT_NAME="${NAME}_${IDX}"
    test iofogctl -q -n "$NS" legacy agent "$AGENT_NAME" status
  done
}

@test "Disconnect from cluster" {
  initAgents
  test iofogctl -q -n "$NS" disconnect
  checkControllerNegative
  checkAgentsNegative
}

@test "Connect to cluster using Kube Config" {
  CONTROLLER_EMAIL=$(cat /tmp/email.txt)
  CONTROLLER_PASS=$(cat /tmp/pass.txt)
  CONTROLLER_ENDPOINT=$(cat /tmp/endpoint.txt)
  test iofogctl -q -n "$NS" connect "$NAME" --kube-config "$KUBE_CONFIG" --email "$CONTROLLER_EMAIL" --pass "$CONTROLLER_PASS"
  checkController
  checkAgents
}

@test "Controller legacy commands after connect with Kube Config" {
  test iofogctl -q -n "$NS" legacy controller "$NAME" iofog list
}

@test "Get Controller logs on K8s after connect with Kube Config" {
  test iofogctl -q -n "$NS" logs controller "$NAME"
}

@test "Get Agent logs" {
  for IDX in "${!AGENTS[@]}"; do
    local AGENT_NAME="${NAME}_${IDX}"
    test iofogctl -q -n "$NS" logs agent "$AGENT_NAME"
  done
}

@test "Disconnect from cluster again" {
  initAgents
  test iofogctl -q -n "$NS" disconnect
  checkControllerNegative
  checkAgentsNegative
}

@test "Connect to cluster using Controller IP" {
  CONTROLLER_EMAIL=$(cat /tmp/email.txt)
  CONTROLLER_PASS=$(cat /tmp/pass.txt)
  CONTROLLER_ENDPOINT=$(cat /tmp/endpoint.txt)
  test iofogctl -q -n "$NS" connect "$NAME" --controller "$CONTROLLER_ENDPOINT" --email "$CONTROLLER_EMAIL" --pass "$CONTROLLER_PASS"
  checkController
  checkAgents
}

# TODO: Enable these if ever possible to do with IP connect
#@test "Get Controller logs after connect with IP" {
#  test iofogctl -q -n "$NS" logs controller "$NAME"
#}
#@test "Get Controller logs on K8s after connect with IP" {
#  test iofogctl -q -n "$NS" logs controller "$NAME"
#}

@test "Delete Agents" {
  initAgents
  for IDX in "${!AGENTS[@]}"; do
    local AGENT_NAME="${NAME}_${IDX}"
    test iofogctl -q -n "$NS" delete agent "$AGENT_NAME"
  done
}

@test "Delete Controller" {
  test iofogctl -q -n "$NS" delete controller "$NAME"
  checkAgentsNegative
  checkControllerNegative
}

@test "Deploy Controller from file" {
  echo "controllers:
- name: $NAME
  kubeconfig: $KUBE_CONFIG
  images:
    controller: $CONTROLLER_IMAGE
    connector: $CONNECTOR_IMAGE
    scheduler: $SCHEDULER_IMAGE
    operator: $OPERATOR_IMAGE
    kubelet: $KUBELET_IMAGE
  iofoguser:
    name: Testing
    surname: Functional
    email: user@domain.com
    password: S5gYVgLEZV" > test/conf/k8s.yaml

  test iofogctl -q -n "$NS" deploy -f test/conf/k8s.yaml
  checkController
}

@test "Deploy Agents from file" {
  initAgents
  echo "agents:" > test/conf/agents.yaml
  for IDX in "${!AGENTS[@]}"; do
    local AGENT_NAME="${NAME}_${IDX}"
    echo "- name: $AGENT_NAME
  user: ${USERS[$IDX]}
  host: ${HOSTS[$IDX]}
  keyfile: $KEY_FILE" >> test/conf/agents.yaml
  done

  test iofogctl -q -n "$NS" deploy -f test/conf/agents.yaml
  checkAgents
}

@test "Test Agent deploy for idempotence" {
  test iofogctl -q -n "$NS" deploy -f test/conf/agents.yaml
  checkAgents
}

@test "Test Controller deploy for idempotence" {
  test iofogctl -q -n "$NS" deploy -f test/conf/k8s.yaml
  checkController
}

@test "Delete all" {
  test iofogctl -q -n "$NS" delete all
  checkControllerNegative
  checkAgentsNegative
}

# TODO: Enable this when a release of Controller is usable here (version needs to be specified for dev package)
#@test "Deploy vanilla Controller" {
#  initVanillaController
#  test iofogctl -q -n "$NS" deploy controller "$NAME" --user "$VANILLA_USER" --host "$VANILLA_HOST" --key-file "$KEY_FILE" --port "$VANILLA_PORT"
#  checkController
#}

@test "Deploy vanilla Controller" {
  initVanillaController
  echo "controllers:
- name: $NAME
  user: $VANILLA_USER
  host: $VANILLA_HOST
  port: $VANILLA_PORT
  keyfile: $KEY_FILE
  version: $VANILLA_VERSION
  packagecloudtoken: $PACKAGE_CLOUD_TOKEN
  iofoguser:
    name: Testing
    surname: Functional
    email: user@domain.com
    password: S5gYVgLEZV" > test/conf/vanilla.yaml

  test iofogctl -q -n "$NS" deploy -f test/conf/vanilla.yaml
  checkController
}

@test "Controller legacy commands after vanilla deploy" {
  test iofogctl -q -n "$NS" legacy controller "$NAME" iofog list
}

@test "Get Controller logs after vanilla deploy" {
  test iofogctl -q -n "$NS" logs controller "$NAME"
}

@test "Deploy Agents against vanilla Controller" {
  test iofogctl -q -n "$NS" deploy -f test/conf/agents.yaml
  checkAgents
}

@test "Delete all" {
  test iofogctl -q -n "$NS" delete all
  checkControllerNegative
  checkAgentsNegative
}

@test "Delete namespace" {
  test iofogctl delete namespace "$NS"
  [[ -z $(iofogctl get namespaces | grep "$NS") ]]
}