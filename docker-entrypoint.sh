#!/bin/bash

#Check if we are asked to process old logs

if [ x${BACKEND_IP} = x"12.34.56.78" ] 
	then
	echo "You need to set the BACKEND_IP"
	echo "Run with:"
	echo "    docker run -e BACKEND_IP=<your_backend_ip> -p 80:80 -p 8081:8081 scollazo/bla"
	exit 1
else
	sed -i "s#proxy_redirect_ip#${BACKEND_IP}#" /etc/nginx/sites-enabled/default
fi


if [ x${LEARNING_MODE} != x"yes" ] 
	then
	sed -i 's/LearningMode;//g' /etc/nginx/naxsi.rules
	echo "LearningMode is disabled - Blocking requests"
	else
	echo "LearningMode is enabled"
fi

if [ x${ELASTICSEARCH_HOST} !=  x"elasticsearch" ]
	then
	sed -i "s/elasticsearch/${ELASTICSEARCH_HOST}/g" /usr/local/etc/nxapi.json
	fi

if ! [ -z ${KIBANA_PASSWORD} ] && [ x${KIBANA_PASSWORD} != x ]
        then
                echo -e "kibana:`perl -le "print crypt(\"${KIBANA_PASSWORD}\","salt")"`" > /etc/nginx/htpasswd
		sed -i 's/# auth/auth/g' /etc/nginx/sites-enabled/kibana
        fi

#Change owner for log files
if [ -d /var/log/nginx ]
	then
	chown www-data.www-data /var/log/nginx -R
	fi

if [ x"$1" = x"debug" ]
	then
		echo "Changed config files. Not starting any daemon"
		exit 0
	fi


	# Wait for the Elasticsearch container to be ready before starting nginx
	echo "Stalling for Elasticsearch"
	while true; do
		    nc -q 1 elasticsearch 9200 2>/dev/null && break
	    done

echo  "Naxsi filtering requests to $BACKEND_IP"

## Ugly hack, but I don't know how to get live logs from nginx to nxtool
## --stdin goes crazy (infinite loop)
## --fifo goes crazy too 
## --syslog didn't work for me with nginx 1.7.9 and
## 	nginx.conf: error_log syslog=localhost:51400 debug;
## So I used logtail, and --file 

/usr/bin/supervisord -nc /etc/supervisor/supervisord.conf

