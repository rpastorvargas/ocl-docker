#!/bin/bash

if [ "$#" != "1" ]; then
	echo "El script necesita 1 parámetro: "
	echo "      1. Número de directorio que se va a procesar. Además, se creará su estructura de ejecución."
	echo "Ejemplo: "
	echo "      $0 directory_number"
	exit 1
fi

#Me situo en el directorio del actual script
cd `dirname $(readlink -f $0)`

if [ -d "../labs/$1" ]; then
	rm -r ../labs/$1	
fi

if [ ! -d "../uploaded/$1" ]; then
	echo "El laboratorio indicado número $1 no ha sido subido al servidor."
	exit 2
fi

#DIR_NAME=$(grep "$1/" "../bbdd/uploads_directories" | cut -d"/" -f4)
#DIR_NAME=$(grep "id\":\"$1\"" ../bbdd/docker_status.json | cut -d"," -f3 | cut -d"\"" -f4)
DIR_NAME=$(ls ../uploaded/$1)

cp -r "../uploaded/$1/$DIR_NAME" "../labs/$1"

cp -r "../bin_lab_source" "../labs/$1/bin"

#Aquí en adelante creamos los scripts necesarios para ejecutar el wrapper con "start_laboratory.sh"
j=0
echo -n "wrapper_add=\"" >../labs/$1/bin/jar_files.sh
for file in `ls ../labs/$1/code/*.jar| xargs -n 1 basename` ;
do
	echo -n wrapper.java.classpath.10$j=../code/$file >>../labs/$1/bin/jar_files.sh
	echo -n " " >>../labs/$1/bin/jar_files.sh
	j=`expr $j + 1`
done
echo -n "\"" >>../labs/$1/bin/jar_files.sh
chmod +rx ../labs/$1/bin/jar_files.sh

#Ahora configuramos el lab.properties para el laboratorio específico
for xmlf in `dir -B ../labs/$1/LEDML_Specification` ;
do
	EXTENSION=$(echo $xmlf | cut -d'.' -f 2)
	if [ "$EXTENSION" == "xml" ] ; then
		echo xmlfile=../LEDML_Specification/$xmlf >>../labs/$1/bin/conf/lab.properties
		break
	fi
done

#En el caso de necesitar especificar la ip al publicar, hay que añadirlo en el "lab.properties".
#Esta ip estará especificada en el fichero de configuración general "labs.conf".
echo `grep -v '^#' ../labs.conf | grep 'publish_ip='` >>../labs/$1/bin/conf/lab.properties

exit 0

