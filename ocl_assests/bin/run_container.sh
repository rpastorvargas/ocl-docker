#!/bin/bash

#Me situo en el directorio del actual script
cd `dirname $(readlink -f $0)`
HOST_DIRECTORY=$(dirname `pwd`)

source ../labs.conf

#Comprobamos si ya fue creado el contenedor anteriormente.
if [ 1 -eq `sudo docker ps -a | grep -c '\<'$CONTAINER_NAME'\>'` ]; then
	echo "The docker container \"$CONTAINER_NAME\" has already been created before."
	exit 1
fi

#Definición de los puertos publicados en el host e inicialización de sistema de asignación de puertos.
NAT_RULES="-p $EXTERNAL_RMIREGISTRYPORT:1099 -p $EXTERNAL_WEB_PORT:8080"

# Escribir en el fichero JSON
# Init all the values !!!
#echo -n "0" >../bbdd/number_of_labs
sed -i '/number_of_labs/ c{"number_of_labs":"0"}' ../bbdd/docker_status.json

#cat /dev/null >../bbdd/active_labs
sed -i '/"active_lab"/ d' ../bbdd/docker_status.json
 
#cat /dev/null >../bbdd/udpport_free
#cat /dev/null >../bbdd/rlabserviceport_free
#cat /dev/null >../bbdd/restport_free
sed -i '/_free":"/ d' ../bbdd/docker_status.json

#cat /dev/null >../bbdd/udpport_in_use
#cat /dev/null >../bbdd/rlabserviceport_in_use
#cat /dev/null >../bbdd/restport_in_use
sed -i '/_used":"/ d' ../bbdd/docker_status.json

for (( i=0; i<${MAX_LABS}; i++ ))
do
	#UDP PORT
	AUX=`expr $INITIAL_UDPPORT $OP_UDPPORT $i` 
	NAT_RULES=$NAT_RULES" ""-p $AUX:$AUX/udp"

	#echo $AUX >>../bbdd/udpport_free
	sed -i "/number_of_labs/a\,{\"udp_free\":\"$AUX\"}" ../bbdd/docker_status.json	
done
for (( i=0; i<${MAX_LABS}; i++ ))
do

	#RLABSERVICE PORT
	AUX=`expr $INITIAL_RLABSERVICEPORT $OP_RLABSERVICEPORT $i` 
	NAT_RULES=$NAT_RULES" ""-p $AUX:$AUX"
	#echo $AUX >>../bbdd/rlabserviceport_free
	sed -i "/number_of_labs/a\,{\"rlab_free\":\"$AUX\"}" ../bbdd/docker_status.json	
done
for (( i=0; i<${MAX_LABS}; i++ ))
do

	#REST PORT
	AUX=`expr $INITIAL_RESTPORT $OP_RESTPORT $i` 
	NAT_RULES=$NAT_RULES" ""-p $AUX:$AUX"
	#echo $AUX >>../bbdd/restport_free
	sed -i "/number_of_labs/a\,{\"rest_free\":\"$AUX\"}" ../bbdd/docker_status.json	
done

#Docker command
docker run -it -d --name=$CONTAINER_NAME $NAT_RULES -v "/etc/localtime:/etc/localtime:ro" -v $HOST_DIRECTORY:$CONTAINER_ROOT related/ocl

echo "Check  for running container with this URL: http://host_dockercontainer_IP:"$EXTERNAL_WEB_PORT"/ocl"
exit 0
