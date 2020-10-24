#! /bin/bash

cd /exchange

if ! test -d ".corona-settings"; then
    mkdir .corona-settings
    echo -1 > .corona-settings/lastcolumn
fi

if pgrep -f "carbon-feeder.py" &>/dev/null; then
  echo "carbon-feeder it is already running"
else
  nohup bash -c "./carbon-feeder.py > .carbon-feeder.output" &>/dev/null &
fi