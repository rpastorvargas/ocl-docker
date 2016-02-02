#!/bin/bash

if [ "$#" != "3" ]; then
	echo "El script necesita 3 parámetros: "
	echo "      1. Nombre del contenedor. 2. Dirección MAC. 3. Dirección IP (CIDR)."
	echo "Ejemplo: "
	echo "      $0 container_name 02:42:ac:11:01:0a 172.17.1.10/16"
	exit 1
fi  

set -e
echo "0. Establezco set -e para que el script termine inmediatamente si un comando termina sin éxito."

CONTAINER_NAME=$1
MACADDR=$2
IPADDR=$3

GATEWAY=172.17.42.1
IPADDR_SINMASK=$(echo $IPADDR | cut -d/ -f1)
EN_EJECUCION="0"
CONTENEDORES=$(sudo docker ps -q)
echo "1. Establecemos ciertas variables a sus valores."

#Comprobamos que la ip no está en uso por otro contenedor y que el contenedor está en ejecución.
for CONT in $CONTENEDORES; do
	NOMBRE_TMP=$(sudo docker inspect --format '{{.Name}}' $CONT | cut -d/ -f2)
	#echo "Nombre del contenedor: $NOMBRE_TMP"
	if [ $NOMBRE_TMP != $CONTAINER_NAME ]; then
		NSPID_TMP=$(sudo docker inspect --format='{{ .State.Pid }}' $CONT)
		#echo "2. El proceso del contenedor $CONT tiene como pid: $NSPID_TMP."

		[ ! -d /var/run/netns ] && sudo mkdir -p /var/run/netns
		#echo "3. Se ha creado, si no existía, el directorio /var/run/netns."

		[ -h /var/run/netns/$NSPID_TMP ] && sudo rm -f /var/run/netns/$NSPID_TMP
		#echo "4. Si ya existe /var/run/netns/$NSPID_TMP lo borra."

		sudo ln -s /proc/$NSPID_TMP/ns/net /var/run/netns/$NSPID_TMP
		#echo "5. Se ha creado el siguiente enlace simbólico /var/run/netns/$NSPID_TMP -> /proc/$NSPID_TMP/ns/net"
		
		#Comparamos las ip's
		IP_TMP=$(sudo ip netns exec $NSPID_TMP ip route get 8.8.8.8 | awk 'NR==1 {print $NF}')
		#echo "6. IP del contenedor $NOMBRE_TMP: $IP_TMP"
		
		if [ $IP_TMP == $IPADDR_SINMASK ]
		then
			echo "Error: La ip $IPADDR_SINMASK está siendo utilizada por el contenedor $NOMBRE_TMP."
			exit 2
		fi

		[ -h /var/run/netns/$NSPID_TMP ] && sudo rm -f /var/run/netns/$NSPID_TMP
		#echo "22. Borra el enlace simbólico creado anteriormente para que otras instrucciones ip netns no lo utilicen."
	elif [ $NOMBRE_TMP == $CONTAINER_NAME ]; then
		EN_EJECUCION="1"	
	fi
done

if [ "$EN_EJECUCION" == "0" ]
then
	echo "Error: El contenedor $CONTAINER_NAME no está en ejecución."
	exit 3
fi

#Ahora modificamos la interfaz eth0 del contenedor asignándole la nueva ip.
NSPID=$(sudo docker inspect --format='{{ .State.Pid }}' $CONTAINER_NAME)
echo "2. El proceso del contenedor $CONTAINER_NAME tiene como pid: $NSPID."

[ ! -d /var/run/netns ] && sudo mkdir -p /var/run/netns
echo "3. Se ha creado, si no existía, el directorio /var/run/netns."

[ -h /var/run/netns/$NSPID ] && sudo rm -f /var/run/netns/$NSPID
echo "4. Si ya existe /var/run/netns/$NSPID lo borra."

sudo ln -s /proc/$NSPID/ns/net /var/run/netns/$NSPID
echo "5. Se ha creado el siguiente enlace simbólico /var/run/netns/$NSPID -> /proc/$NSPID/ns/net"

LOCAL_IFNAME="veth0plocal${NSPID}"
GUEST_IFNAME="veth0pguest${NSPID}"
echo "6. Se establecen las variables LOCAL_IFNAME ($LOCAL_IFNAME) y GUEST_IFNAME ($GUEST_IFNAME)."

sudo ip link add $LOCAL_IFNAME type veth peer name $GUEST_IFNAME
echo "7. Se han creado dos interfaces emparejadas nuevas ($LOCAL_IFNAME y $GUEST_IFNAME) para configurarlas seguidamente."

sudo brctl addif docker0 $LOCAL_IFNAME
echo "8. Se ha añadido la interfaz $LOCAL_IFNAME al puente de la interfaz docker0."

sudo ip link set $LOCAL_IFNAME up
echo "9. Se ha activado la interfaz $LOCAL_IFNAME en la máquina host."

sudo ip link set $GUEST_IFNAME netns $NSPID
echo "10. Se ha introducido la interfaz GUEST_IFNAME ($GUEST_IFNAME) en el espacio de red del contenedor $CONTAINER_NAME."

sudo ip netns exec $NSPID ip link set eth0 down
echo "11. Se ha desactivado la interfaz eth0 en el contenedor $CONTAINER_NAME."

sudo ip netns exec $NSPID ip link delete eth0
echo "12. Se ha borrado la interfaz eth0 en el contenedor $CONTAINER_NAME."

sudo ip netns exec $NSPID ip link set dev $GUEST_IFNAME name eth0
echo "13. Se ha nombrado la interfaz $GUEST_IFNAME como interfaz eth0."

sudo ip netns exec $NSPID ip link set eth0 down
echo "14. Se ha desactivado la interfaz eth0 en el contenedor $CONTAINER_NAME."

[ "$MACADDR" ] && sudo ip netns exec $NSPID ip link set dev eth0 address $MACADDR
echo "15. Se ha asignado a la interfaz eth0 del contenedor $CONTAINER_NAME la dirección MAC: $MACADDR."

sudo ip netns exec $NSPID ip addr add $IPADDR dev eth0
echo "16. Se ha asignado la dirección $IPADDR a la interfaz eth0 del contenedor $CONTAINER_NAME."

sudo ip netns exec $NSPID ip link set eth0 up
echo "17. Se vuelve a activar la interfaz eth0 en el contenedor $CONTAINER_NAME para cargar la nueva configuración."

[ "$GATEWAY" ] && {
sudo ip netns exec $NSPID ip route delete default >/dev/null 2>&1 && true
}
echo "18. Borra la route por defecto de la que tuviera el contenedor."

[ "$GATEWAY" ] && {
sudo ip netns exec $NSPID ip route get $GATEWAY >/dev/null 2>&1 || \
sudo ip netns exec $NSPID ip route add $GATEWAY/32 dev eth0
sudo ip netns exec $NSPID ip route replace default via $GATEWAY
}
echo "19. Se ha asignado como gateway la ip de la interfaz docker0."

# Give our ARP neighbors a nudge about the new interface
if which arping > /dev/null 2>&1
then
IPADDR=$(echo $IPADDR | cut -d/ -f1)
sudo ip netns exec $NSPID arping -c 1 -A -I eth0 $IPADDR > /dev/null 2>&1 || true
else
echo "***************** Warning: arping not found; interface may not be immediately reachable"
fi
echo "21. Avisa a los vecinos ARP acerca de la nueva interfaz creada."

# Remove NSPID to avoid `ip netns` catch it.
[ -h /var/run/netns/$NSPID ] && sudo rm -f /var/run/netns/$NSPID
echo "22. Borra el enlace simbólico creado anteriormente para que otras instrucciones ip netns no lo utilicen."

exit 0


