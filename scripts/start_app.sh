#!/bin/bash

# Mark the trap signals!!!
trap "echo TRAPed signal, stopping tomcat; /usr/local/tomcat/bin/catalina.sh stop; echo catalina stopped;exit 0;" SIGHUP SIGINT SIGQUIT SIGKILL SIGTERM

echo "Checking for related ocl assests"
# Test if the volume is empty
if [ ! -f /related_ocl/labs.conf ]; then

    # Copy the contents from the container image into the volume
    cp -R /ocl_assests_template/* /related_ocl
    echo "Assets copied..."
fi

source  /related_ocl/labs.conf

# Check for env values: INSTALL_CONTAINER_NAME
if [ "$INSTALL_CONTAINER_NAME" = "" ]
then
   echo "INSTALL_CONTAINER_NAME is not defined as an ENV variable"
   exit 0
else
   echo "Setting CONTAINER NAME in labs.conf to "$INSTALL_CONTAINER_NAME
   sed -i "s/^.*\bCONTAINER_NAME="*"\b.*$/CONTAINER_NAME=\"$INSTALL_CONTAINER_NAME\"/" /related_ocl/labs.conf
fi

# Check for env values: INSTALL_MAX_LABS
if [ "$INSTALL_MAX_LABS" = "" ]
then
   # Default value is 16
   echo "INSTALL_MAX_LABS is not set. Using default value: 16 labs"
   INSTALL_MAX_LABS=16
fi
echo "Setting max labs in the container: "$INSTALL_MAX_LABS
sed -i "s/^.*\bMAX_LABS=*\b.*$/MAX_LABS=$INSTALL_MAX_LABS/" /related_ocl/labs.conf

# Check for env values: INSTALL_PUBLISH_IP_NEEDED
if $INSTALL_PUBLISH_IP_NEEDED ;  then
   if [ "$INSTALL_PUBLISH_IP" = "" ]
   then
      echo "INSTALL_PUBLISH_IP_NEEDED is set to true, but no INSTALL_PUBLISH_IP is set. Container IP will be used..."
      sed -i "s/^.*\bpublish_ip=*\b.*$/#publish_ip=$INSTALL_PUBLISH_IP/" /related_ocl/labs.conf
   else
      echo "Setting public ip used in the container for lab's publising IP: "$INSTALL_PUBLISH_IP
      sed -i "s/^.*\bpublish_ip=*\b.*$/publish_ip=$INSTALL_PUBLISH_IP/" /related_ocl/labs.conf
   fi
else
   sed -i "s/^.*\bpublish_ip=*\b.*$/#publish_ip=$INSTALL_PUBLISH_IP/" /related_ocl/labs.conf
fi

# Check for env values: INSTALL_INITIAL_UDPPORT
if [ "$INSTALL_INITIAL_UDPPORT" = "" ]
then
   echo "INSTALL_INITIAL_UDPPORT is  not defined as an ENV variable. Using default value: 10000"
   INSTALL_INITIAL_UDP_PORT=10000
fi
echo "Setting INITIAL_UDPPORT in labs.conf to "$INSTALL_INITIAL_UDP_PORT
sed -i "s/^.*\bINITIAL_UDPPORT="*"\b.*$/INITIAL_UDPPORT=$INSTALL_INITIAL_UDP_PORT/" /related_ocl/labs.conf


# Check for env values: INSTALL_INITIAL_RLABSERVICEPORT
if [ "$INSTALL_INITIAL_RLABSERVICEPORT" = "" ]
then
   echo "INSTALL_INITIAL_RLABSERVICEPORT is  not defined as an ENV variable. Using default value: 1098"
   INSTALL_INITIAL_RLABSERVICEPORT=1098
fi
echo "Setting INITIAL_RLABSERVICEPORT in labs.conf to "$INSTALL_INITIAL_RLABSERVICEPORT
sed -i "s/^.*\bINITIAL_RLABSERVICEPORT="*"\b.*$/INITIAL_RLABSERVICEPORT=$INSTALL_INITIAL_RLABSERVICEPORT/" /related_ocl/labs.conf

# Check for env values: INSTALL_INITIAL_RESTPORT
if [ "$INSTALL_INITIAL_RESTPORT" = "" ]
then
   echo "INSTALL_INITIAL_RESTPORT is  not defined as an ENV variable. Using default value: 9999"
   INSTALL_INITIAL_RESTPORT=9999
fi
echo "Setting INITIAL_RESTPORT in labs.conf to "$INSTALL_INITIAL_RESTPORT
sed -i "s/^.*\bINITIAL_RESTPORT="*"\b.*$/INITIAL_RESTPORT=$INSTALL_INITIAL_RESTPORT/" /related_ocl/labs.conf


# Check for env values: INSTALL_EXTERNAL_WEB_PORT
if [ "$INSTALL_EXTERNAL_WEB_PORT" = "" ]
then
   echo "INSTALL_EXTERNAL_WEB_PORT is  not defined as an ENV variable. Using default value: 8080"
   INSTALL_EXTERNAL_WEB_PORT=8080
fi
echo "Setting EXTERNAL_WEB_PORT in labs.conf to "$INSTALL_EXTERNAL_WEB_PORT
sed -i "s/^.*\bEXTERNAL_WEB_PORT="*"\b.*$/EXTERNAL_WEB_PORT=$INSTALL_EXTERNAL_WEB_PORT/" /related_ocl/labs.conf


# delay some time for network configuration in host container
# For example bluemix needs 10 seconds to configure...
echo "sleeping 10 seconds..."
sleep 10

# Now start the app here
echo "starting tomcat"
exec /usr/local/tomcat/bin/catalina.sh run
#startup.sh

echo "[hit enter key to exit] or run 'docker stop <container>'"
read

# stop service and clean up here
echo "stopping tomcat, after the read command"
catalina.sh stop
# shutdown.sh

echo "exited $0"
