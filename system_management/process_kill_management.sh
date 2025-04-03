#!/bin/bash

#----------------------------------------Opciones----------------------------------------------------

mandarSenales() {

    while true; do
        read -p "Introduce el nombre de la aplicación: " application
        pid=$(pgrep -x "$application" 2>/dev/null)
        [ -z "$pid" ] && {
            echo "La aplicación '$application' no está en uso. Introduce un nombre válido."
            sleep 3s
            continue
        } || break #--Si la aplicación está en uso, se sale del bucle de las preguntas y continúa con la gestión.
    done

    kill -l

    process_info=$(ps -o pid,ppid,pri,state,cmd -C "$application" 2>/dev/null)

    echo "Información del proceso: $application"
    echo "$process_info"

    read -p "Introduce el nombre de la señal: " signal
    read -p "Número del PID: " pid

    kill -s $signal $pid

    echo "La señal: $signal ha sido enviada al proceso $application" && sleep 3s
}

echo "------- Programa para mandar señales a los procesos ----------"

#-----------------------------Main---------------------------------------

clear
opcion=0
while [[ $opcion -ne 3 ]]; do
    clear
    echo "1. Mandar señales a los procesos"
    echo "2. Consultar nombres e información de los procesos activos"
    echo "3. Salir"
    read -p "Introduce una opción: " opcion
    case $opcion in
    1) mandarSenales ;;
    2) ps -ef ;;
    3) echo "Saliendo..." ;;
    *) echo "Opción inválida... debe ser 1, 2 o 3" ;;
    esac
    read -p "Pulsa Enter para continuar" enter
done
