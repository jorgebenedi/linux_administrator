#!/bin/bash

# funciones para realizar consultar a los dominios

function nameServer(){ # Mostrara los DNS de ese dominio, también debes mostrar sus ips
    echo "Los DNS del dominio $nameDomain son:"
    dig @${dns} NS $nameDomain +short | while read elemento; do # busca nameServers de nombres asociados a un dominio raiz
        echo "Nombre del DNS: $elemento"
        echo "Direccion IP: $(dig $elemento +short)"
    done
}

function mailExchange(){ # Mostrara los servidores de correo de ese dominio, también debes mostrar sus ips
    dig @${dns} mx $nameDomain +short  | sort -n | while read -r preference mx; do 
        echo "nombre del servidor de correo: $mx (preferencia $preference)"
        ips=$(dig +short $mx)
        echo "IPs:" 
        echo "$ips"
    done
        
    
}

function startAuthority(){ # Muestra lo que significa cada parte del registro SOA que te devuelve y su valor
    echo "Obteniendo registro SOA para el dominio $nameDomain..."
    soaRecord=$(dig @${dns} +short SOA $nameDomain)

    if [ -z "$soaRecord" ]; then
        echo "No SOA record found for domain $nameDomain"
    else
        IFS=' ' read -r primaryNs hostMaster serial refresh retry expire minimum <<< "$soaRecord"
        echo "Registro SOA para el dominio $nameDomain:"
        echo "  Servidor DNS principal: $primaryNs"
        echo "  Correo del administrador: $hostMaster"
        echo "  Número de serie: $serial"
        echo "  Intervalo de actualización: $refresh segundos"
        echo "  Intervalo de reintento: $retry segundos"
        echo "  Tiempo de expiración: $expire segundos"
        echo "  Tiempo mínimo de TTL: $minimum segundos"
    fi
}

function CAA(){
echo "Obteniendo registro CAA para el dominio $nameDomain"
caaRecords=$(dig @${dns} CAA $nameDomain +short)

if [ -z "$caaRecords" ]; then
    echo "Registro de CAA no encontado para $nameDomain"
else
    echo "Registro CAA para el dominio $nameDomain"
    echo "$caaRecords" | while read -r flags tag value; do
        echo "Flags: $flags"
        echo "Tag: $tag"
        echo "Value: $value"
    done
    echo "El registro CAA especifica que autoridades de certificación (CAs) puede emitir certificados SSL/TLS para este dominio"
fi
}

function TXT(){ # Muestra para que sirve este tipo de RR y sus valores para ese dominio
echo "Obteniendo registros TXT para el dominio $nameDomain..."
    txtRecords=$(dig @${dns} +short TXT $nameDomain)

    if [ -z "$txtRecords" ]; then
        echo "No tiene registros TXT del dominio $nameDomain"
    else
        echo "Registros TXT para el dominio $nameDomain:"
        echo "$txtRecords" | while read -r txt; do
            echo "  Valor: $txt"
        done
        echo "Los registros TXT se utilizan para almacenar datos arbitrarios en forma de texto."
        echo "Usos comunes incluyen:"
        echo "  - Verificación de dominio: Usado por servicios como Google, Microsoft, etc., para verificar que eres el propietario del dominio."
        echo "  - SPF (Sender Policy Framework): Especifica los servidores de correo que están autorizados para enviar correo en nombre del dominio."
        echo "  - DKIM (DomainKeys Identified Mail): Almacena claves públicas para la verificación de firmas DKIM."
        echo "  - Información general: Almacenar cualquier tipo de información que el administrador del dominio considere útil."
    fi


}

function AXFR(){  # Consulta AXFR, para trasnferir zona completa, no siempre funciona
    echo "Obteniendo servidores de nombres para el dominio $nameDomain..."
    nsServers=$(dig @${dns} +short NS $nameDomain)

    if [ -z "$nsServers" ]; then
        echo "No encontro name servers para el dominio $nameDomain"
        return 1
    fi

    echo "Probando solicitud AXFR para el dominio $nameDomain..."
    for ns in $nsServers; do
        echo "Intentando transferencia de zona (AXFR) desde el servidor: $ns"
        axfrResult=$(dig @$ns AXFR $nameDomain)

        if [[ $axfrResult == *"Transfer failed"* ]] || [[ $axfrResult == *"connection timed out"* ]] || [[ $axfrResult == *"XFR size"* ]]; then
            echo "Transferencia de zona (AXFR) fallida o bloqueada en el servidor: $ns"
        else
            echo "Transferencia de zona (AXFR) exitosa desde el servidor: $ns"
            echo "$axfr_result"
            break
        fi
    done

    echo "La consulta AXFR se utiliza para transferir la zona completa de un dominio desde un servidor DNS autorizado a otro."
    echo "Esta operación es comúnmente utilizada para la replicación de datos DNS entre servidores DNS autorizados."
    echo "Nota: Muchos servidores DNS están configurados para rechazar estas solicitudes por razones de seguridad."

}


# Funciones para especificar la DNS para hacer consultas

function dnsManual(){
        read -p "Introduce el DNS a mano: " dns
        if [ -z "$dns" ]; then
        dns="8.8.8.8"
        fi
        mainMenu
        
}



function dnsPreconfig(){
        [ -z "$(whereis -b nmcli | awk '{print $2}')" ] && apt install -y network-manager
        dnsArray=($(nmcli dev show | grep 'IP4.DNS' | awk '{print $2}' | head -n 2))

}



# Menus para las consultas
function nameDomain(){
    read -p "Introduce el dominio a obtener info (ej: google.com): " nameDomain
    if [ -z "$nameDomain" ]; then
        echo "Error deberas introducir un nombre de dominio"
        mainMenu
    fi
    option=0
    while [[ $option -ne 7 ]]; do
    clear
    echo "=================================="
    echo "== Consultas resolucion directa =="
    echo "=================================="
    echo "TIPO DE RR (registro en archivos de zona) a consultar para DOMINIO"
    echo "=================================================================="
    echo "Utilizando un servidor DNS especificado $dns para realizar consultas DNS al dominio: $nameDomain"
    echo "1. tipo de RR = NS (Name Server o DNS)"
    echo "2. tipo de RR = MX (Mail eXchange)"
    echo "3. tipo de RR = SOA (Start of Authority)"
    echo "4. tipo de RR = CAA"
    echo "5. tipo de RR = TXT"
    echo "6. tipo de solicitud AXFR"
    echo "7. Salir"
    read -p "Introduce una opción: " option

    case $option in
    1) nameServer ;;
    2) mailExchange ;;
    3) startAuthority ;;
    4) CAA ;;
    5) TXT ;;
    6) AXFR ;;
    7) mainMenu  ;;
    esac
    read -p "Pulsa enter para continuar" enter
done

}



function mainMenu(){
option=0
while [[ $option -ne 4 ]]; do
clear
   dnsPreconfig
   echo "==========================="
   echo "======DNS A CONSULTAR======"
   echo "==========================="
   echo "1. Introduce DNS a mano"
   echo "2. DNS-1 configurado ${dnsArray[0]}"
   echo "3. DNS-2 configurado ${dnsArray[1]}"
   echo "4. Salir"
   echo "[S/s] siguiente paso]"
   read -p "Introduce una opción: " option

    case $option in
    1) dnsManual ;;
    2) dns=${dnsArray[0]} ;;
    3) dns=${dnsArray[1]} ;;
    4) exit ;;
    S|s) nameDomain;;
    esac
    read -p "Pulsa enter para continuar" enter
done

}
  
mainMenu







