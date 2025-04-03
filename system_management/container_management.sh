#!/bin/bash

listarContenedores() {
    echo "1 - Todos los contenedores"
    echo "2 - Contenedores en ejecución"
    read -p "Introduce una opción: " opcion
    case $opcion in
        1) docker ps -a ;;
        2) docker ps ;;
        *) echo "Opción inválida" ;;
    esac
}

pararContenedores() {
    comprobarContenedor || return 1
    docker container stop "$name_Container" && echo "$name_Container apagado"
}

arrancarContenedores() {
    comprobarContenedor || return 1
    docker container start "$name_Container" && echo "$name_Container arrancado"
}

borrarContenedor() {
    comprobarContenedor || return 1
    docker container stop "$name_Container" && docker container rm "$name_Container"
}

ejecutarComando() {
    comprobarContenedor || return 1
    docker exec -i -t "$name_Container" /bin/bash || {
        echo "No se puede ejecutar el comando porque la máquina está detenida"
        read -p "¿Quieres ejecutar el contenedor con la misma imagen? [s/n]: " respuesta
        case $respuesta in
            "s")
                imagen_Contenedor=$(docker ps -a | grep "$name_Container" | awk '{print $2}')
                docker stop "$name_Container" 2>/dev/null && docker rm "$name_Container" 2>/dev/null
                docker run -i -t --name "$name_Container" "$imagen_Contenedor"
                ;;
            "n") echo "Saliendo..." ;;
            *) echo "Opción inválida" ;;
        esac
    }
}

crearContenedor() {
    docker_Exec="docker run -it"
    read -p "Introduce el nombre del contenedor: " nuevo_Container
    docker_Exec+=" --name $nuevo_Container"
    read -p "¿Quieres ejecutarlo en modo demonio? [s/n]: " demon
    [[ "$demon" == "s" ]] && docker_Exec+=" -d"

    read -p "¿Quieres definir variables? [s/n]: " variables
    [[ "$variables" == "s" ]] && setVariables || return 1

    read -p "Introduce la imagen del contenedor: " imagen_Container
    [ -z "$imagen_Container" ] && { echo "La variable está vacía"; return 1; }

    mapfile -t ARRAY < <(docker search "$imagen_Container" | awk 'NR>1 {print $1}')
    CONTADOR=1
    for i in "${ARRAY[@]}"; do
        echo "$CONTADOR. $i"
        CONTADOR=$((CONTADOR + 1))
    done

    read -p "Elige una opción: " Image_Number
    isInteger "$Image_Number" || { echo "Opción incorrecta"; return 1; }

    docker_Exec+=" ${ARRAY[$((Image_Number - 1))]}"
    eval "$docker_Exec"
    echo "Se ha creado el contenedor $nuevo_Container"
}

setVariables() {
    read -p "¿Cuántas variables quieres añadir? " VAR_SIZE
    isInteger "$VAR_SIZE" || { echo "Debes introducir un número entero"; return 1; }
    for ((i = 1; i <= VAR_SIZE; i++)); do
        read -p "Nombre de la variable: " VAR_NAME
        read -p "Valor de la variable: " VAR_VALUE
        docker_Exec+=" -e ${VAR_NAME}=${VAR_VALUE}"
    done
}

isInteger() {
    [[ $1 =~ ^[0-9]+$ ]]
}

comprobarContenedor() {
    read -p "Introduce el nombre del contenedor: " name_Container
    [ -z "$name_Container" ] && { echo "El nombre está vacío"; return 1; }
    docker container ps -a | grep -q "$name_Container" || { echo "No existe el contenedor en el sistema"; return 1; }
}

while true; do
    clear
    echo "1-Listar contenedores"
    echo "2-Parar contenedor"
    echo "3-Arrancar contenedor"
    echo "4-Borrar contenedor"
    echo "5-Ejecutar comando"
    echo "6-Crear contenedor"
    echo "7-Salir"
    read -p "Introduce la opción: " opcion
    case $opcion in
        1) listarContenedores ;;
        2) pararContenedores ;;
        3) arrancarContenedores ;;
        4) borrarContenedor ;;
        5) ejecutarComando ;;
        6) crearContenedor ;;
        7) echo "Saliendo..."; exit 0 ;;
        *) echo "Opción inválida" ;;
    esac
    read -p "Pulsa Enter para continuar..." enter
done
