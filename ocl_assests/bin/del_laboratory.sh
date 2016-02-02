#!/bin/bash

if [ "$#" != "1" ]; then
	echo "El script necesita 1 parámetro: "
	echo "      1. Directorio identificativo asignado al laboratorio."
	echo "Ejemplo: "
	echo "      $0 directorio_laboratorio"
	exit 1
fi  

#echo Me situo en el directorio del actual script
cd `dirname $(readlink -f $0)`

source ../labs.conf

#echo Elimino el directorio de laboratorios procesados si existe
if [ -d "../labs/$1" ]; then
	rm -rf ../labs/$1
fi

#echo Elimino el directorio de laboratorios fuentes si existe
if [ -d "../uploaded/$1" ]; then
	rm -rf ../uploaded/$1
fi

#echo Ahora leo el nombre del fichero comprimido del fichero docker_status.json
AUX_SOURCE_FILE=`grep id\":\"$1\" ../bbdd/docker_status.json | cut -d"\"" -f12`
AUX_SOURCE_FILE=$AUX_SOURCE_FILE.zip

#echo Fichero fuente $AUX_SOURCE_FILE

#echo Elimino el fichero zip del directorio de subida de comprimidos si existe
if [ -f $FOLDER_SOURCE_FILES$AUX_SOURCE_FILE ]; then
	#echo Borro $FOLDER_SOURCE_FILES$AUX_SOURCE_FILE
	rm -f $FOLDER_SOURCE_FILES$AUX_SOURCE_FILE
fi

#echo Elimino la entrada del laboratorio del fichero docker_status.json
if [ 0 -ne `grep -c id\":\"$1\" ../bbdd/docker_status.json` ] ; then
	sed -i "/id\":\"$1\"/ d" ../bbdd/docker_status.json
fi

