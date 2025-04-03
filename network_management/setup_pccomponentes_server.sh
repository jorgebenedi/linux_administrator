#!/bin/bash

function checkUser() {
    echo "///-------------------------PCCOMPONENTES SCRIPT-------------------------///"
    echo "///-----------------------------------system-failure-------------------------------------///"
    if [[ "$(whoami)" != "root" ]]; then
        echo "El script tiene que ser ejecutado como usuario root"
        exit 1
    fi
}

function downloadApache2() {
    echo "Descargando paquetes necesarios..."
    apt update && apt upgrade -y
    apt install -y apache2
}

function enableModules() {
    echo "Habilitando módulos necesarios..."
    a2enmod auth_digest
    service apache2 restart
}

function servidorWebPccomponentes() {
    echo "Configurando servidor web para PCComponentes..."
    mkdir -p /var/www/html/pccomponentes
    echo "<h1>Bienvenido a PC-componentes, tu tienda online de electronica</h1>" > /var/www/html/pccomponentes/index.html
}

function configPrivateZone() {
    echo "Configurando zona privada..."
    htdigest -c /etc/apache2/PCCOMPONENTES-USERS ZONA-ADMINISTRACION gerente1
    htdigest /etc/apache2/PCCOMPONENTES-USERS ZONA-ADMINISTRACION comercial1
    htdigest /etc/apache2/PCCOMPONENTES-USERS ZONA-ADMINISTRACION comercial2

    chown www-data:www-data /etc/apache2/PCCOMPONENTES-USERS
    chmod 440 /etc/apache2/PCCOMPONENTES-USERS

    mkdir -p /var/www/html/pccomponentes/ZONA-ADMINISTRACION
    echo "<p>Listado de los pedidos...zona privada</p>" > /var/www/html/pccomponentes/ZONA-ADMINISTRACION/listadoPedidos.html
}

# Zona administracion sera el realm, la zona que si intentamos acceder nos mandara una authentifiacion, esta se basara en una pequeña base de
# datos llamada PCCOMPONENTES-USERS especificada en AuthUserFile
function configPcomponentesApache() {
    


    echo "Configurando Apache para PCComponentes..."
    cat << EOF > /etc/apache2/sites-available/pccomponentes.conf
<VirtualHost *:8080>
    ServerName www.pccomponentes.es
    DocumentRoot /var/www/html/pccomponentes

    <Directory /var/www/html/pccomponentes/ZONA-ADMINISTRACION/> 
        AuthName "ZONA-ADMINISTRACION"
        AuthType Digest
        AuthDigestProvider file
        AuthUserFile /etc/apache2/PCCOMPONENTES-USERS
        Require valid-user
    </Directory>
</VirtualHost>
EOF

    a2ensite pccomponentes.conf
    service apache2 restart
}

checkUser

clear
opcion=0
while [[ $opcion -ne 5 ]]; do
    clear
    echo "--------------------------------"
    echo "----PCCOMPONENTES-APACHE2------"
    echo "--------------------------------"
    echo "1. Descarga de paquetes"
    echo "2. Habilitar módulos"
    echo "3. Montar servidor web PCCOMPONENTES"
    echo "4. Configurar archivo PCComponentes en Apache2"
    echo "5. Salir"
    read -p "Introduce una opción: " opcion
    case $opcion in
        1) downloadApache2 ;;
        2) enableModules ;;
        3) servidorWebPccomponentes ;;
        4) 
            configPrivateZone
            configPcomponentesApache
            ;;
        5) exit ;;
        *) echo "Opción no válida. Intente de nuevo." ;;
    esac
    read -p "Pulsa enter para continuar" enter
done
