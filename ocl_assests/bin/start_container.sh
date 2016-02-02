#!/bin/bash

#Run with sudo

#Me situo en el directorio del actual script
cd `dirname $(readlink -f $0)`

source ../labs.conf

#Comprobamos si el contenedor ya fue creado anteriormente y está parado.
if [ 0 -eq `sudo docker ps -f status=exited | grep -c '\<'$CONTAINER_NAME'\>'` ]; then
	echo "The docker container \"$CONTAINER_NAME\" is not stopped."
	exit 1
fi

sudo docker start $CONTAINER_NAME

exit 0
