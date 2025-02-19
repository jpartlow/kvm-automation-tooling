#!/bin/bash
if [ -d "$1" ]; then
  echo '{"exists": true}'
else
  echo '{"exists": false}
fi
