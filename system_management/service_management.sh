#!/bin/bash

# Función para gestionar servicios

gestionarServicios(){
    clear
    read -p "Introduce el nombre del servicio: " serv

    echo -e "\t\t ESTADO DEL SERVICIO"
    echo -e "\t\t -------------------"

    systemctl --no-pager status "$serv".service
    echo -e "-------------------------------------------- \n\n"

    estado=$(systemctl is-enabled "$serv".service)
    if [ "$estado" == "enabled" ]; then
        isrunning=$(systemctl list-units --type=service | grep "$serv.service" | awk '{print $4}')
        if [ "$isrunning" == "running" ]; then
            read -p "El servicio está en ejecución. ¿Deseas pararlo? [s/n]: " resp
            [[ "$resp" == "s" || "$resp" == "S" ]] && systemctl stop "$serv".service
        else
            read -p "El servicio está detenido. ¿Deseas iniciarlo? [s/n]: " resp
            [[ "$resp" == "s" || "$resp" == "S" ]] && systemctl start "$serv".service
        fi
    else
        read -p "El servicio está deshabilitado. ¿Deseas habilitarlo? [s/n]: " resp
        [[ "$resp" == "s" || "$resp" == "S" ]] && systemctl enable "$serv".service
    fi
}

# Función para listar servicios importantes

listaServicios(){
    echo "Lista de servicios más importantes:"
    echo "
    - sshd: Servidor SSH para conexiones remotas seguras.
    - apache2 o httpd: Servidor web Apache.
    - mysqld: Servidor de base de datos MySQL.
    - postgresql: Servidor de base de datos PostgreSQL.
    - cron: Demonio de programación de tareas.
    - atd: Demonio de planificación de tareas de una sola vez.
    - docker: Plataforma para crear, probar y desplegar aplicaciones con contenedores."

    read -p "Introduce el servicio para verificar si está instalado: " serv
    systemctl list-units --type=service | grep "$serv" >/dev/null && echo "$serv está instalado" || echo "$serv no está instalado"
}

# Menú principal

clear
opcion=0
while [[ $opcion -ne 3 ]]; do
    clear
    echo "------------------------- Gestión de servicios -----------------------------"
    echo "1. Gestionar servicios"
    echo "2. Lista de servicios"
    echo "3. Salir"
    read -p "Introduce una opción: " opcion
    case $opcion in
        1) gestionarServicios ;;
        2) listaServicios ;;
        3) echo "Saliendo..." ;;
        *) echo "Opción inválida. Debe ser entre 1 y 3." ;;
    esac
    read -p "Pulsa Enter para continuar..." enter
    echo "$enter"
done
