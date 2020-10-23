#! /bin/bash -x

#exec 1> /home/centos/graphite.log 2>&1

GRAPHITEBASEDIR=/opt/graphite

sudo yum install httpd mod_ssl -y
sudo chkconfig httpd on

sudo yum -y install git nmap-ncat httpd-devel

sudo pip3 install mod_wsgi
sudo cp /usr/local/lib64/python3.6/site-packages/mod_wsgi/server/mod_wsgi-py36.cpython-36m-x86_64-linux-gnu.so /usr/lib64/httpd/modules/mod_wsgi.so

sudo pip3 install pycairo
	
cd /usr/local/src
sudo git clone https://github.com/graphite-project/graphite-web.git
sudo git clone https://github.com/graphite-project/carbon.git
sudo git clone https://github.com/graphite-project/whisper.git
sudo git clone https://github.com/graphite-project/ceres.git

sudo pip3 install -r /usr/local/src/graphite-web/requirements.txt
sudo pip3 install -r /usr/local/src/carbon/requirements.txt
sudo pip3 install -r /usr/local/src/whisper/requirements.txt
 
cd /usr/local/src/carbon/
sudo python3 setup.py install
 
cd /usr/local/src/graphite-web/
sudo python3 setup.py install
 
cd /usr/local/src/whisper/
sudo python3 setup.py install

cd /usr/local/src/ceres/
sudo python3 setup.py install
 
sudo cp $GRAPHITEBASEDIR/conf/carbon.conf.example $GRAPHITEBASEDIR/conf/carbon.conf
sudo cp $GRAPHITEBASEDIR/conf/storage-schemas.conf.example $GRAPHITEBASEDIR/conf/storage-schemas.conf
sudo cp $GRAPHITEBASEDIR/conf/storage-aggregation.conf.example $GRAPHITEBASEDIR/conf/storage-aggregation.conf
sudo cp $GRAPHITEBASEDIR/conf/relay-rules.conf.example $GRAPHITEBASEDIR/conf/relay-rules.conf
sudo cp $GRAPHITEBASEDIR/webapp/graphite/local_settings.py.example $GRAPHITEBASEDIR/webapp/graphite/local_settings.py
sudo cp $GRAPHITEBASEDIR/conf/graphite.wsgi.example $GRAPHITEBASEDIR/conf/graphite.wsgi
sudo cp $GRAPHITEBASEDIR/examples/example-graphite-vhost.conf /etc/httpd/conf.d/graphite.conf
 
sudo cp /usr/local/src/carbon/distro/redhat/init.d/carbon-* /etc/init.d/
sudo chmod +x /etc/init.d/carbon-*

DJANGOADMIN=`find / -name django-admin.py -print -quit`

if ! test -f "$DJANGOADMIN"; then 
  echo ERROR: django-admin.py not found!
  exit 1
fi
	
cd $GRAPHITEBASEDIR
#create database
sudo PYTHONPATH=$GRAPHITEBASEDIR/webapp/ $DJANGOADMIN migrate  --noinput --settings=graphite.settings
 
#import static files
sudo PYTHONPATH=$GRAPHITEBASEDIR/webapp $DJANGOADMIN collectstatic --noinput --settings=graphite.settings

#set permissions, we let apache group having fullaccess, so centos can put/del files into
sudo chown -R apache:apache $GRAPHITEBASEDIR/storage/
sudo chmod -R 0770 $GRAPHITEBASEDIR/storage
sudo chown -R apache:apache $GRAPHITEBASEDIR/static/
sudo chmod -R 0770 $GRAPHITEBASEDIR/static
sudo chown -R apache:apache $GRAPHITEBASEDIR/webapp/
sudo chmod -R 0770 $GRAPHITEBASEDIR/webapp

# add centos to apache group
sudo chown centos:centos $GRAPHITEBASEDIR
sudo usermod -a -G apache centos

sudo cat <<EOF > /etc/httpd/conf.d/graphite.conf
   LoadModule wsgi_module modules/mod_wsgi.so

   WSGISocketPrefix /var/run/wsgi

<VirtualHost *:80>

    ServerName graphite
    DocumentRoot "$GRAPHITEBASEDIR/webapp"
    ErrorLog $GRAPHITEBASEDIR/storage/log/webapp/error.log
    CustomLog $GRAPHITEBASEDIR/storage/log/webapp/access.log common

    WSGIDaemonProcess graphite-web processes=5 threads=5 display-name='%{GROUP}' inactivity-timeout=120
    WSGIProcessGroup graphite-web
    WSGIApplicationGroup %{GLOBAL}
    WSGIImportScript $GRAPHITEBASEDIR/conf/graphite.wsgi process-group=graphite-web application-group=%{GLOBAL}

    WSGIScriptAlias / $GRAPHITEBASEDIR/conf/graphite.wsgi

    Alias /static/ $GRAPHITEBASEDIR/static/

    <Directory $GRAPHITEBASEDIR/static/>
            <IfVersion < 2.4>
                    Order deny,allow
                    Allow from all
            </IfVersion>
            <IfVersion >= 2.4>
                    Require all granted
            </IfVersion>
    </Directory>

    <Directory $GRAPHITEBASEDIR/conf/>
            <IfVersion < 2.4>
                    Order deny,allow
                    Allow from all
            </IfVersion>
            <IfVersion >= 2.4>
                    Require all granted
            </IfVersion>
    </Directory>
</VirtualHost>
EOF

sudo firewall-cmd --zone=public --permanent --add-service=http
sudo firewall-cmd --zone=public --permanent --add-service=https
# Open the carbon port for world
sudo firewall-cmd --zone=public --permanent --add-port=2003/tcp
# Open Grafana
sudo firewall-cmd --zone=public --permanent --add-port=3000/tcp
sudo firewall-cmd --reload


sudo systemctl enable carbon-cache
sudo systemctl start carbon-cache

sudo wget https://dl.grafana.com/oss/release/grafana-7.2.2-1.x86_64.rpm
sudo yum install -y grafana-7.2.2-1.x86_64.rpm
sudo rm -f 
sudo systemctl grafana-7.2.2-1.x86_64.rpmenable httpd


sudo systemctl enable grafana
sudo systemctl start grafana


PATHINTERN=/intern
SCRIPT=setup.sh
FILE=$PATHINTERN/$SCRIPT
if test -d "$PATHINTERN"; then
  sudo chown centos:centos $PATHINTERN
  # Don't break the script if no files were found when bash -e is set
  sudo chown -R centos:centos $PATHINTERN/* || true
  sudo chmod +x $PATHINTERN/*.{sh,py} || true
  if test -f "$FILE"; then
    pushd $PATHINTERN
    ./$SCRIPT
    popd
  fi
fi

sudo systemctl start httpd
