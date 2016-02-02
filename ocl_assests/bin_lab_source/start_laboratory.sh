#!/bin/bash

echo "Starting RLAB Componente Server (Random Generator System)...."
echo "Press CTRL-C to stop server. If any problem will ocurr, the rlab log file located in the log directory will indicate the problem".

#Me situo en el directorio del actual script
cd `dirname $(readlink -f $0)`

# Aqui se ponen los jar que implementan 
# las vistas/modulos para que los cargue al arrancar la 
# aplicacion
# Con este script consigo definir la variable "wrapper_add" que contiene los jar necesarios
source ./jar_files.sh

# Conf file
configFile=./conf/lab.properties

# Conf file for Wrapper
configWrapperFile=./conf/wrapper.conf

./wrapper_x86_64 -c $configWrapperFile wrapper.logfile=./log/wrapper.log wrapper.pidfile=./wrapper.pid $wrapper_add  wrapper.app.parameter.1=$configFile &

