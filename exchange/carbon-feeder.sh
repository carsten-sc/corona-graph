#! /bin/bash

cd /exchange

if pgrep -f "carbon-feeder.py" &>/dev/null; then
  echo "carbon-feeder it is already running"
else
  ./carbon-feeder.py > logs/carbon-feeder.output &
fi