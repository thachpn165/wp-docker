#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../test_helper/bats-support/load"
load "${BATS_TEST_DIRNAME}/../test_helper/bats-assert/load"

setup() {
  # Tạo docker giả lập để ghi nhận lệnh được gọi
  export PATH_BACKUP=$PATH
  export PATH="/tmp/fakebin:$PATH"
  mkdir -p /tmp/fakebin

  # Fake docker
  cat <<'EOF' > /tmp/fakebin/docker
#!/bin/bash
if [[ "$1" == "ps" ]]; then
  echo "php-container"
elif [[ "$1" == "network" && "$2" == "ls" ]]; then
  echo "default"
elif [[ "$1" == "volume" && "$2" == "ls" ]]; then
  echo "wp-volume"
fi
EOF

  chmod +x /tmp/fakebin/docker

  source ./shared/scripts/functions/docker_utils.sh
}

teardown() {
  rm -rf /tmp/fakebin
  export PATH=$PATH_BACKUP
}

@test "is_container_running returns 0 if container exists" {
  run is_container_running "php-container"
  [ "$status" -eq 0 ]
}

@test "is_network_exist returns 0 if network exists" {
  run is_network_exist "default"
  [ "$status" -eq 0 ]
}

@test "is_volume_exist returns 0 if volume exists" {
  run is_volume_exist "wp-volume"
  [ "$status" -eq 0 ]
}
