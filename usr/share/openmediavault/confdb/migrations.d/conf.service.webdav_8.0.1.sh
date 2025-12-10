#!/bin/sh

set -e

. /usr/share/openmediavault/scripts/helper-functions

if ! omv_config_exists "/config/services/webdav/path"; then
  omv_config_add_key "/config/services/webdav" "path" "webdav"
fi

if ! omv_config_exists "/config/services/webdav/userisolation"; then
  omv_config_add_key "/config/services/webdav" "userisolation" "0"
fi

omv_module_set_dirty webdav

exit 0

