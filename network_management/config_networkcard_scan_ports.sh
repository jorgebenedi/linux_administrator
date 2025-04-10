#!/bin/bash

function showEstablishedConnections() { 
    echo "Mostrando conexiones establecidas (ESTABLISHED):" 
    echo "¿Qué protocolo deseas ver? (TCP/UDP):" 
    read protocol 

    if [ "$protocol" == "TCP" ]; then  
    
        netstat -n -t | grep -E "ESTABLISHED|ESTABLECIDO" | awk '{ 

        print "puerto_local_abierto: " substr($4, index($4, ":") + 1) " - host_remoto: " substr($5, 0, index($5, ":") - 1) " - puerto_remoto: " substr($5, index($5, ":") + 1)

    }'
    elif [ "$protocol" == "UDP" ]; then 
        netstat -n -u | grep -E "ESTABLISHED|ESTABLECIDO" | awk '{

        print "puerto_local_abierto: " substr($4, index($4, ":") + 1) " - direccion_ip_router: " substr($5, 0, index($5, ":") - 1) " - puerto_remoto: " substr($5, index($5, ":") + 1)

    }'
    else
        echo "Protocolo no válido. Saliendo..."
    fi
}

function openPorts() { 
            echo "=====================TCP======================="
            netstat -ltn | awk 'NR>2 {print $4}' | cut -d ":" -f2 | sort -n | uniq | while read port; do 
            serviceTcp=$(grep -w $port/tcp /etc/services | awk '{print $1}' | uniq) 
            if [ -z "$serviceTcp" ] ; then
                service="No definido"
             else
                service="$serviceTcp"
            fi

            echo "Puerto: $port - Servicio: $service"
            done

             echo "=====================UDP======================="
             netstat -lun | awk 'NR>2 {print $4}' | cut -d ":" -f2 | sort -n | uniq | while read port; do 
             serviceUdp=$(grep -w $port/udp /etc/services | awk '{print $1}' | uniq) 
            if [ -z "$serviceUdp" ] ; then 
                service="No definido" 
            else
                service="$serviceUdp"
            fi

            echo "Puerto: $port - Servicio: $service"
            done
    

}





function configCard() { 
    read -p "Introduce la nueva dirección IP: " ip
    read -p "Introduce la máscara de red: " mask

    echo "Eliminando configuraciones de IP actuales para añadir las nuevas"
    ip addr flush dev $card
    if [ $? -ne 0 ]; then
        echo "No pudo eliminar las configuraciones de IP actuales."
        return 1
    fi

    echo "Estableciendo nueva dirección IP y máscara de red..."
    ip addr add $ip/$mask dev $card
    if [ $? -ne 0 ]; then
        echo "Error al añadir la nueva dirección IP."
        return 1
    fi

    echo "Levantando la interfaz de red"
    ip link set $card up
    if [ $? -ne 0 ]; then
        echo "No se pudo levantar la interfaz de red."
        return 1
    fi

    echo "La tarjeta $card ha sido configurada con éxito"
    echo "IP: $ip"
    echo "Máscara: $mask"
    ifconfig
}

function configRouting() { 


    read -p "Introduce la dirección del router : " router
    if [ $? -ne 0 ]; then
        echo "No se pudo configurar el router"
        return 1
    fi

    ipMask=$(ip addr show $card | awk '/inet / {print $2}' | head -n 1) 
    ipRed=$(ipcalc -n $ipMask | grep Network | awk '{print $2}') 
    routerRed=$(ipcalc -n $router | grep 'Network' | awk '{print $2}')
    
    
    if [ $ipRed == $routerRed ];then  
        ip route add default via $router dev $card 
        echo "Salida a Internet configurada a través del router $router en la tarjeta $card."
    else 
        echo "La red del router $routerRed no coincide con la red de la IP $ipRed"
        
    fi

   
}
    

function checkCard() {
    ip=$(ip address show $card | grep -e "inet " | awk '{print $2}' | awk -F "/" '{print $1}')
    echo "Mandamos 10-paquetes icmp echo request a su ip..."
    ping -c 10 -t 2 -s 65507 $ip >/dev/null
    if [ $? -ne 0 ]; then
        echo "Respuesta al ping incorrecta :  TARJETA DE RED NO RESPONDE"
        return 1
    fi

    echo "Paquetes ICMP recibidos correctamente por la direccion $ip"

    ipRouter=$(route -n | grep "UG" | awk '{print $2}')
    echo "Mandamos 10-paquetes icmp echo request a su ip..."
    ping -c 10 -t 2 -s 65507 $ipRouter >/dev/null
    if [ $? -ne 0 ]; then
        echo "Respuesta al ping incorrecta :  ROUTER NO RESPONDE"
    fi
    echo "Paquetes ICMP recibidos correctamente por el router $ipRouter"

    hostname="www.google.com"
    echo "Realizando ping a $hostname..."

    ping -c 10 -t 2 -s 65507 $hostname >/dev/null
    if [ $? -ne 0 ] ; then
        echo "tarjeta bien configurada"
    else
        echo "MÁQUINA NO RESPONDE."
        read -p "Introduce la dirección IP del primer DNS: " dns1
        read -p "Introduce la dirección IP del segundo DNS: " dns2

        if [ -e "/etc/resolv.conf" ]; then
            sudo cp /etc/resolv.conf /etc/resolv.conf.bak

            sudo bash -c "echo 'nameserver $dns1' > /etc/resolv.conf"
            sudo bash -c "echo 'nameserver $dns2' >> /etc/resolv.conf"

            echo "Servidores DNS configurados correctamente:"
            echo "DNS-1: $dns1"
            echo "DNS-2: $dns2"
        else
             echo "El archivo /etc/resolv.conf no existe. No se pudieron configurar los servidores DNS."
        fi
    fi

   
}



function showCard(){
    echo -e "Cards\n---------"
    cards=($(ip -br link | awk '{print $1}' | grep -v lo))

    for i in "${!cards[@]}"; do
        echo "'$(($i+1))'.${cards[$i]}"
    done

    read -p "Introduce la opcion: " cardOption

    if [ "$cardOption" -gt 0 ] && [ "$cardOption" -le ${#cards[@]} ]; then
        card=${cards[$(($cardOption-1))]}
        return 1
    else
        echo "No has introducido una opcion valida"
        mainMenu
    fi  


    
}
#---------------------------------------------------------MENUS----------------------------------------------------------------------------------------------
#MENU 1
function configParameters() {
   
    showCard
    echo "--------------------------------"
    echo "---MENU DE TARJETA: $card---"
    echo "--------------------------------"
    echo "A. CONFIGURAR PARAMETROS DE CAPA DE RED"
    echo "B. CONFIGURAR ENRUTAMIENTO"
    echo "C. COMPROBAR TARJETA"
    echo "D. VOLVER AL MENU PRINCIPAL"
    read -p "Opción: " option

    case $option in
    A | a)
        configCard
        ;;
    B | b)
        echo "Configurando enrutamiento para $card"
        configRconfig
        ;;
    C | c)
        echo "Comprobando tarjeta $card"
        checkCard
        ;;
    D | d) mainMenu;;
    *) 
    esac
}

#MENU 2
function showConnectionsPorts() {

    while :; do
        clear
        echo "--------------------------------------"
        echo "-CONEXIONES A HOST-REMOTOS y PUERTOS ABIERTOS-"
        echo "--------------------------------------"

        echo "1. Mostrar conexiones establecidas (ESTABLISHED)"
        echo "2. Mostrar puertos abiertos que tienes en tu maquina (LISTEN) "
        echo "3. ---VOLVER AL MENU PRINCIPAL---"
        read -p "Opcion: " option

        case $option in
        1)
            showEstablishedConnections || {
                echo "Error al buscar conexiones tcp establecidas"
                exit 1
            }
            ;;
        2)
            openPorts || {
                echo "El escaneo ha finalizado"
                exit 1
            }
            ;;
        3)
            echo "Saliendo"
            mainMenu
            ;;
        *)
            echo "Opción no válida."
            ;;
        esac
        read -p "Presiona enter para continuar"
    done
}

function mainMenu(){
clear
option=0
while [[ $option -ne 3 ]]; do
    echo "--------------------------------"
    echo "ADMIN PARAMETROS DE CONEXION EQUIPO"
    echo "--------------------------------"
    echo "1. Configurar parametros de conexion tarjeta"
    echo "2. Ver conexiones/puertos"
    echo "3. Salir"
    read -p "Introduce una opción: " option

    case $option in
    1) configParameters ;;
    2) showConnectionsPorts ;;
    3) exit ;;
    *) echo "Opción no válida" ;;
    esac
    read -p "Pulsa enter para continuar" enter
done

}

mainMenu
