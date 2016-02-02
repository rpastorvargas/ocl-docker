#!/bin/bash

#Run with sudo

#Me situo en el directorio del actual script
cd `dirname $(readlink -f $0)`

source ../labs.conf

#Comprobamos si el contenedor ya fue creado anteriormente y está ejecutándose.
if [ 0 -eq `sudo docker ps -f status=running | grep -c '\<'$CONTAINER_NAME'\>'` ]; then
	echo "The docker container \"$CONTAINER_NAME\" is not running."
	exit 1
fi

sudo docker stop $CONTAINER_NAME

exit 0
