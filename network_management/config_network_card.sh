#!/bin/bash

configIPMask(){
    read -p "Introduce la nueva dirección IP: " ip
    read -p "Introduce la la máscara de red: " mascara

    echo "Eliminando configuraciones de IP actuales para añadir las nuevas"
    ip addr flush dev $tarjeta
    if [ $? -ne 0 ]; then
        echo "No pudo eliminar las configuraciones de IP actuales."
        return 1
    fi
    
    echo "Estableciendo nueva dirección IP y máscara de red..."
    ip addr add $ip/$mascara dev $tarjeta
    if [ $? -ne 0 ]; then
        echo "Error al añadir la nueva dirección IP."
        return 1
    fi
    
    echo "Levantando la interfaz de red"
    ip link set $tarjeta up
    if [ $? -ne 0 ]; then
        echo "No se pudo levantar la interfaz de red."
        return 1
    fi
    
    echo "La tarjeta $tarjeta ha sido configurada con exito"
    echo "IP: $ip"
    echo "Máscara: $mascara"
    ifconfig
}

function configOutputInternet(){
    read -p "Introduce la direccion del router : " router
    ip route add default via $router dev $tarjeta
    if [ $? -ne 0 ]; then
        echo "Error no se pude configurar el router"
        return 1
    fi

    echo "Salida a Internet configurada a través del router $router en la tarjeta $tarjeta."


}

function networkCardCheck(){
    read -p "Introduce la dirección IP: " ip
    echo "Mandamos 4-paquetes icmp echo request a su ip..."
    ping -c 4 $ip > /dev/null
    if [ $? -ne 0 ];then
        echo "Respuesta al ping incorrecta :  TARJETA DE RED NO RESPONDE"
        return 1
    fi

    echo "Paquetes ICMP recibidos correctamente por la direccion $ip" 

    read -p "Introduce la dirección IP del router: " iprouter
    echo "Mandamos 4-paquetes icmp echo request a su ip..."
    ping -c 4 $iprouter > /dev/null
    if [ $? -ne 0 ];then
        echo "Respuesta al ping incorrecta :  ROUTER NO RESPONDE"
        return 1
    fi
    echo "Paquetes ICMP recibidos correctamente por el router $iprouter"

    ping -c 4 $ip &> /dev/null && { dns_server=$(awk '/^nameserver/{print $2; exit}' /etc/resolv.conf); 
    if [ -n "$dns_server" ]; then ping -c 4 "$dns_server" &> /dev/null || { echo "DNS CAÍDO!!. Cambia el servidor DNS."; return 1; };
    else echo "No hay ninguna dns configurada..."; return 1; fi; } || { echo "TARJETA NO RESPONDE. Verifique la configuración de red."; return 1; }
    echo "Paquetes ICMP recibidos por la dns"

    hostname=${hostname:-"www.google.com"}  
    echo "Realizando ping a $hostname..."
    
    if ping -c 3 $hostname > /dev/null 2>&1; then
        echo "!!!! TARJETA BIEN CONFIGURADA Y CON CONEXIÓN AL EXTERIOR !!!!"
    else
        echo "NOMBRE DE MÁQUINA NO RESPONDE. Prueba con otra..."
    fi

}
    clear
    echo "Quieres descargar algunos paquetes necesarios [S/N]"
    read respuesta
    if [ $respuesta = "S" ]; then  apt install -y net-tools iproute2 iputils-ping; echo "Descargando paquetes necesarios..." ; fi 

read -p "Introduce el nombre de la tarjeta: " tarjeta

if ip link show "$tarjeta" > /dev/null 2>&1; then
    mac=$(ip link show "$tarjeta" | awk '/ether/ {print $2}')
    echo "La dirección MAC de la tarjeta $tarjeta es: $mac"

    
    clear
    opcion=0
    while [[ $opcion -ne 2 ]]; do
        clear
        echo "--------------------------------"
        echo "-------ConfigNetworkCard--------"
        echo "--------------------------------"
        echo "1. CONFIGURAR IP y MASCARA DE RED" 
        echo "2. CONFIGURAR SALIDA A INTERNET"
        echo "3. COMPROBAR TARJETA"
        echo "4. Salir"
        read -p "Introduce una opcion: " opcion
        case $opcion in
        1) configIPMask ;;
        2) configOutputInternet ;;
        3) networkCardCheck ;;
        4) exit ;;
        esac
        read -p "Pulsa enter para continuar" enter
        echo "$enter"
    done
fi




