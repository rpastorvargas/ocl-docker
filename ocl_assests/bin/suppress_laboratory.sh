#!/bin/bash

if [ "$#" != "1" ]; then
	echo "El script necesita 1 parámetro: "
	echo "      1. Directorio donde se encuentra el laboratorio al que se le envía la señal SIGINT (Control + C)."
	echo "Ejemplo: "
	echo "      $0 directorio_laboratorio"
	exit 1
fi  

#Me situo en el directorio del actual script
cd `dirname $(readlink -f $0)`

source ../labs.conf

if [ ! -d "../labs/$1" ]; then
	echo "The specified laboratory does not exist."
	exit 2
fi

# if [ 0 -eq `sudo docker ps | grep -c '\<'$CONTAINER_NAME'\>'` ]; then
#	echo "The docker container \"$CONTAINER_NAME\" is not started."
#	exit 3
# fi

#if [ 0 -eq `grep -c '^'$1'$' ../bbdd/active_labs` ] ; then
if [ 0 -eq `grep -c active_lab\":\"$1\" ../bbdd/docker_status.json` ] ; then
	echo "The laboratory is not active."
	exit 4
else
	#sed -i '/^'$1'$/d' ../bbdd/active_labs
	sed -i "/active_lab\":\"$1\"/ d" ../bbdd/docker_status.json
fi

#Ahora realizo la liberación de los puertos

AUX_UDP=`grep "^udpport=" ../labs/$1/bin/conf/lab.properties | cut -d"=" -f2`
#sed -i '/^'$AUX_UDP'/d' ../bbdd/udpport_in_use
sed -i "/udp_used\":\"$AUX_UDP\"/ d" ../bbdd/docker_status.json
#echo $AUX_UDP >>../bbdd/udpport_free
sed -i "/number_of_labs/a\,{\"udp_free\":\"$AUX_UDP\"}" ../bbdd/docker_status.json

AUX_RLAB=`grep "^rlabserviceport=" ../labs/$1/bin/conf/lab.properties | cut -d"=" -f2`
#sed -i '/^'$AUX_RLAB'/d' ../bbdd/rlabserviceport_in_use
sed -i "/rlab_used\":\"$AUX_RLAB\"/ d" ../bbdd/docker_status.json
#echo $AUX_RLAB >>../bbdd/rlabserviceport_free
sed -i "/number_of_labs/a\,{\"rlab_free\":\"$AUX_RLAB\"}" ../bbdd/docker_status.json

AUX_REST=`grep "^restport=" ../labs/$1/bin/conf/lab.properties | cut -d"=" -f2`
#sed -i '/^'$AUX_REST'/d' ../bbdd/restport_in_use
sed -i "/rest_used\":\"$AUX_REST\"/ d" ../bbdd/docker_status.json
#echo $AUX_REST >>../bbdd/restport_free
sed -i "/number_of_labs/a\,{\"rest_free\":\"$AUX_REST\"}" ../bbdd/docker_status.json

#LABS_ACTIVE=`sed -n '1p' ../bbdd/number_of_labs`
LABS_ACTIVE=$(grep "number_of_labs" ../bbdd/docker_status.json | cut -d"\"" -f4)
let AUX_MAXS=$LABS_ACTIVE-1
#echo -n $AUX_MAXS >../bbdd/number_of_labs
sed -i "/number_of_labs/ c{\"number_of_labs\":\"$AUX_MAXS\"}" ../bbdd/docker_status.json

sed -i '/^rmiport=/d' ../labs/$1/bin/conf/lab.properties
sed -i '/^udpport=/d' ../labs/$1/bin/conf/lab.properties
sed -i '/^rlabserviceport=/d' ../labs/$1/bin/conf/lab.properties
sed -i '/^restport=/d' ../labs/$1/bin/conf/lab.properties

#PID=$(docker inspect --format {{.State.Pid}} $CONTAINER_NAME)
#echo "1. PID=$PID"
#PID_CONTAINER=$(awk '{ print $1 }' ../labs/$1/bin/wrapper.pid)
#echo "2. PID_CONTAINER=$PID_CONTAINER"
#nsenter --target $PID --mount --uts --ipc --net --pid kill -SIGINT $PID_CONTAINER

PID_CONTAINER=$(awk '{ print $1 }' ../labs/$1/bin/wrapper.pid)
#kill -SIGINT $PID_CONTAINER
kill -SIGTERM $PID_CONTAINER

exit 0
