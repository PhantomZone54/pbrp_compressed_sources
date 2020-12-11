#!/bin/bash
echo $$ > /tmp/keepalive.pid
while true; do
  echo "." && sleep 300
done

