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

function servidorWebApache() {
    ruta_servidor=/var/www/html
    echo "Introduce el directorio donde se va a alojar el servidor"
    read dir_server
    echo "Configurando servidor web para $dir_server"
    mkdir -p "$ruta_servidor"/"$dir_server"
    echo "<h1>Bienvenido a PC-componentes, tu tienda online de electrónica</h1>" > "$ruta_servidor"/"$dir_server"/"index.html"


    mkdir -p "$ruta_servidor/$dir_server/ZONA-ADMINISTRACION"
    echo "Creando zona administracion en: $ruta_servidor/$dir_server/ZONA-ADMINISTRACION"
    echo "<p>Listado de los pedidos...zona privada</p>" > "$ruta_servidor/$dir_server/ZONA-ADMINISTRACION/listadoPedidos.html"
}

function configPrivateZone() {
    echo "Configurando zona privada..."

    echo "Introduce el nombre de la base de datos:"
    read dataBaseName

    echo "Introduce el número de usuarios que deseas crear:"
    read numUsers

    echo "Creando usuarios..."
    usernames=()  # Declaramos un arreglo vacío para almacenar los nombres de usuario
    for ((i=1; i<=$numUsers; i++)); do
        echo "Introduce el nombre de usuario $i:"
        read username
        usernames+=("$username")  # Agregamos el nombre de usuario al arreglo
    done

    # Crear la primera entrada en la base de datos con la opción -c
    htdigest -c /etc/apache2/"$dataBaseName" ZONA-ADMINISTRACION "${usernames[0]}"

    # Iteramos sobre el arreglo de nombres de usuario para agregarlos al archivo de base de datos
    for ((i=1; i<$numUsers; i++)); do
        htdigest /etc/apache2/"$dataBaseName" ZONA-ADMINISTRACION "${usernames[$i]}"
    done

    chown www-data:www-data /etc/apache2/"$dataBaseName"
    chmod 440 /etc/apache2/"$dataBaseName"
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
    echo "3. Montar servidor web en apache2 con zona-privada"
    echo "4. Configurar usuarios para la auth en apache2"
    echo "5. Configurar archivo web en Apache2"
    echo "6. Salir"
    read -p "Introduce una opción: " opcion
    case $opcion in
        1) downloadApache2 ;;
        2) enableModules ;;
        3) servidorWebApache ;;
        4) configPrivateZone ;;
        5) configPcomponentesApache ;;
        6) exit ;;
        *) echo "Opción no válida. Intente de nuevo." ;;
    esac
    read -p "Pulsa enter para continuar" enter
done
