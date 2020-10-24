#! /bin/bash

cd /exchange

if pgrep -f "carbon-feeder.py" &>/dev/null; then
  echo "carbon-feeder it is already running"
else
  nohup bash -c "./carbon-feeder.py > .carbon-feeder.output" &>/dev/null &
fi