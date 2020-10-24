#! /bin/bash

PATHINTERN=/exchange

# Install the sample dashboard
curl -X "POST" "http://localhost:3000/api/dashboards/db" -H "Content-Type: application/json" --data-binary @../common/sample_dashboard.json --user admin:admin

FILE=$PATHINTERN/$SCRIPT

if ! test -d "$PATHINTERN"; then
  exit 1
fi

sudo chown centos:centos $PATHINTERN
# Don't break the script if no files were found when bash -e is set
sudo chown -R centos:centos $PATHINTERN/* || true
sudo chmod +x $PATHINTERN/{*.sh,*.py} || true
pushd $PATHINTERN
sudo sed -i 's/\r$//' {*.sh,*.py} || true
sudo pip3 install -r requirements.txt

mkdir .corona-settings
mkdir logs

popd

crontab <<EOF
SHELL=/bin/bash
30 0 * * * service covid-feeder restart 2>&1 
EOF

sudo su
cat <<EOF > /etc/systemd/system/covid-feeder.service
[Unit]
Description=Corona carbon feeder
After=network.target
After=carbon-cache.service
After=network-online.target

[Service]
User=centos
WorkingDirectory=${PATHINTERN}/
ExecStart=${PATHINTERN}/carbon-feeder.sh
Type=forking

[Install]
WantedBy=multi-user.target
EOF
exit

sudo systemctl enable covid-feeder.service

# Seting timezone from europe/berlin to utc
sudo unlink /etc/localtime 
sudo ln -s /usr/share/zoneinfo/UTC /etc/localtime

./carbon-feeder.sh





