#!/bin/sh
set -e

MOUNTED_DIR="/webdav"
LIGHTTPD_USER="lighttpd"

if [ -d "$MOUNTED_DIR" ]; then
  MOUNTED_UID=$(stat -c "%u" "$MOUNTED_DIR")
  MOUNTED_GID=$(stat -c "%g" "$MOUNTED_DIR")

  echo "Mounted directory UID: $MOUNTED_UID  GID: $MOUNTED_GID"

  CURRENT_UID=$(id -u "$LIGHTTPD_USER")
  CURRENT_GID=$(id -g "$LIGHTTPD_USER")

  echo "Current Lighttpd user UID: $CURRENT_UID"
  echo "Current Lighttpd user GID: $CURRENT_GID"

  # UID가 다르면 변경
  if [ "$MOUNTED_UID" != "$CURRENT_UID" ]; then
    if getent passwd "$MOUNTED_UID" > /dev/null; then
      echo "UID $MOUNTED_UID already exists, skipping usermod"
    else
      echo "Changing Lighttpd user UID to: $MOUNTED_UID"
      usermod -u "$MOUNTED_UID" "$LIGHTTPD_USER"
    fi
  fi

  # GID가 다르면 변경
  if [ "$MOUNTED_GID" != "$CURRENT_GID" ]; then
    if getent group "$MOUNTED_GID" > /dev/null; then
      echo "GID $MOUNTED_GID already exists, skipping groupmod"
    else
      echo "Changing Lighttpd user GID to: $MOUNTED_GID"
      groupmod -g "$MOUNTED_GID" "$LIGHTTPD_USER"
    fi
  fi
else
  echo "Warning: Mounted directory '$MOUNTED_DIR' not found."
fi

# Nginx 또는 Lighttpd 실행
exec "$@"