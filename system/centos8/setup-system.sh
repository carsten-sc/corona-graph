#! /bin/bash

PATHINTERN=/exchange
GRAPHITEBASEDIR=/opt/graphite


# configure carbon retention schema

# we need to add the correct retention at first of the file so we create
# a new file and append the before moved old one

mv $GRAPHITEBASEDIR/conf/storage-schemas.conf ./storage-schemas.conf
cat <<EOF > $GRAPHITEBASEDIR/conf/storage-schemas.conf
[corona_daily]
pattern = ^corona\.*
retentions = 1d:10y
EOF

cat ./storage-schemas.conf >> $GRAPHITEBASEDIR/conf/storage-schemas.conf

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

if [ "$no_auto_import" != true ]; then
  crontab <<EOF
  SHELL=/bin/bash
  30 0 * * * sudo service covid-feeder restart 2>&1 
EOF
fi

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

if [ "$no_auto_import" != true ]; then
  sudo systemctl enable covid-feeder.service
fi

# Seting timezone from europe/berlin to utc
sudo unlink /etc/localtime 
sudo ln -s /usr/share/zoneinfo/UTC /etc/localtime

if [ "$no_initial_import" != true ]; then
  ./carbon-feeder.sh
fi





