#!/bin/bash

if [ "$#" != "1" ]; then
	echo "El script necesita 1 parámetro: "
	echo "      1. Directorio donde se encuentra el laboratorio a activar."
	echo "Ejemplo: "
	echo "      $0 directory_of_laboratory"
	exit 1
fi  

#Me situo en el directorio del actual script
cd `dirname $(readlink -f $0)`

source ../labs.conf

if [ ! -d "../labs/$1" ]; then
	echo "The specified laboratory does not exist."
	exit 2
fi

#LABS_ACTIVE=`sed -n '1p' ../bbdd/number_of_labs`
LABS_ACTIVE=$(grep "number_of_labs" ../bbdd/docker_status.json | cut -d"\"" -f4)

if [ $MAX_LABS -le $LABS_ACTIVE ] ; then
	echo "It have exceeded the maximum number of active laboratories."
	exit 3
fi

#if [ 0 -eq `sudo docker ps | grep -c '\<'$CONTAINER_NAME'\>'` ]; then
#	echo "The docker container \"$CONTAINER_NAME\" is not started."
#	exit 4
#fi

#if [ 1 -eq `grep -c '^'$1'$' ../bbdd/active_labs` ] ; then
if [ 1 -eq `grep -c active_lab\":\"$1\" ../bbdd/docker_status.json` ] ; then
	echo "The laboratory is already active."
	exit 5
else
	#echo $1 >>../bbdd/active_labs
	sed -i "/number_of_labs/a\,{\"active_lab\":\"$1\"}" ../bbdd/docker_status.json
fi

#Ahora realizo la asignación de puertos al laboratorio.

#AUX_UDP=`sed -n '1p' ../bbdd/udpport_free`
AUX_UDP=`grep -m1 udp_free ../bbdd/docker_status.json | cut -d"\"" -f4`
#sed -i '/^'$AUX_UDP'/d' ../bbdd/udpport_free
sed -i "/udp_free\":\"$AUX_UDP\"/ d" ../bbdd/docker_status.json
#echo $AUX_UDP >>../bbdd/udpport_in_use
sed -i "/number_of_labs/a\,{\"udp_used\":\"$AUX_UDP\"}" ../bbdd/docker_status.json

#AUX_RLAB=`sed -n '1p' ../bbdd/rlabserviceport_free`
AUX_RLAB=`grep -m1 rlab_free ../bbdd/docker_status.json | cut -d"\"" -f4`
#sed -i '/^'$AUX_RLAB'/d' ../bbdd/rlabserviceport_free
sed -i "/rlab_free\":\"$AUX_RLAB\"/ d" ../bbdd/docker_status.json
#echo $AUX_RLAB >>../bbdd/rlabserviceport_in_use
sed -i "/number_of_labs/a\,{\"rlab_used\":\"$AUX_RLAB\"}" ../bbdd/docker_status.json

#AUX_REST=`sed -n '1p' ../bbdd/restport_free`
AUX_REST=`grep -m1 rest_free ../bbdd/docker_status.json | cut -d"\"" -f4`
#sed -i '/^'$AUX_REST'/d' ../bbdd/restport_free
sed -i "/rest_free\":\"$AUX_REST\"/ d" ../bbdd/docker_status.json
#echo $AUX_REST >>../bbdd/restport_in_use
sed -i "/number_of_labs/a\,{\"rest_used\":\"$AUX_REST\"}" ../bbdd/docker_status.json

let AUX_MAXS=$LABS_ACTIVE+1
#echo -n $AUX_MAXS >../bbdd/number_of_labs
sed -i "/number_of_labs/ c{\"number_of_labs\":\"$AUX_MAXS\"}" ../bbdd/docker_status.json


# Check the property in the file
if grep "^rmiport=*" ../labs/$1/bin/conf/lab.properties
 then
   # Change the property
   sed -i "s/^.*\brmiport=*\b.*$/rmiport=$RMIREGISTRYPORT/" ../labs/$1/bin/conf/lab.properties
else
   # Write the property
   echo rmiport=$RMIREGISTRYPORT >>../labs/$1/bin/conf/lab.properties
fi
echo udpport=$AUX_UDP >>../labs/$1/bin/conf/lab.properties
echo rlabserviceport=$AUX_RLAB >>../labs/$1/bin/conf/lab.properties
echo restport=$AUX_REST >>../labs/$1/bin/conf/lab.properties

#sudo docker exec -d $CONTAINER_NAME $CONTAINER_ROOT/labs/$1/bin/start_laboratory.sh

# Execute lab !!!
$CONTAINER_ROOT/labs/$1/bin/start_laboratory.sh

# Pause some time...
# Wrapper starts the app, but returns inmediately so
# wrapper.pid in lab directory is not writted
sleep 2

# check for PID file (lab is running...)
PID_FILE=$CONTAINER_ROOT/labs/$1/bin/wrapper.pid
echo $PID_FILE
if [ -f $PID_FILE ];
then
   echo "Lab started..."
   exit 0
else
   echo  "Laboratory was not published. Pid file of running lab do not exist --> "$PID_FILE
   exit 6
fi

exit 0
