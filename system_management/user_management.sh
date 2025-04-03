#!/bin/bash

COLOR_ROJO="\e[31m"
COLOR_BG_ROJO="\e[37;41m"
COLOR_VERDE="\e[32m"
COLOR_AMARILLO="\e[33m"
COLOR_AZUL="\e[34m"
COLOR_MAGENTA="\e[35m"
COLOR_CYAN="\e[36m"
COLOR_RESET="\e[0m"

#------------------------------------------------opciones------------------------------------------------


crearUsuario() {
    getUser || return 1
    getPasswd || return 1
    getGroup || return 1
    read -p "Ingresa los detalles del usuario(Nombre, apellido, telefono): " comments
    sudo useradd -g "$name_Group" -c "$comments" "$name_User" >/dev/null 2>/dev/null && echo "Usuario creado"

    echo "$name_User":"$name_Password" | sudo chpasswd 2>/dev/null || {
        echo "Error cambiado la contraseña"
        return 1
    }

}

borrarUsuario() {
    getUser || return 1
    validarUsuario || return 1
    read -p "Estas seguro de que quieres borrar el usuario[s/n]: " respuesta_Borrado
    if [ "$respuesta_Borrado" == "S" ] || [ "$respuesta_Borrado" == "s" ]; then
        sudo userdel -r "$name_User" >/dev/null 2>/dev/null
        echo "El usuario $name_User ha sido borrado"
    else
        echo "Usuario no borrado"
        return 1
    fi
}

cambiarPassword() {
    getUser || return 1
    validarUsuario || return 1
    getPasswd || return 1
    echo "$name_User:$name_Password" | sudo chpasswd 2>/dev/null || {
        echo "El usuario aún no tiene contraseña"
        return 1
    }
    echo "La contraseña del usuario $name_User ha cambiado"

}

aniadirGrupo(){
    getUser || return 1
    validarUsuario || return 1
    getGroup || return 1
    sudo usermod -aG "$name_Group" "$name_User"  || { echo "No se puede añadir al grupo"
    return 1
     }
    echo "El usuario $name_User ha sido añadido $group_Nuevo"
}

#------------------------------------------------funciones reutilizables------------------------------------------------


getUser() {
    read -p "Ingresa el nombre de usuario: " name_User
    [ -z $name_User ] && {
        echo "No puede estar en blanco"
        sleep 2s
        return 1
    }
    return 0
}

getPasswd() {
    read -p "Ingresa el contrasena de usuario: " name_Password
    [ -z $name_Password ] && {
        echo "No puede estar en blanco"
        sleep 2s
        return 1
    }
    return 0
}

getGroup() {
    read -p "Ingresa el grupo del usuario: " name_Group
    [ -z $name_Group ] && {
        echo "No puede estar en blanco"
        sleep 2s
        return 1
    }

    # Si el grupo existe o no existe
    grep -e "^$name_Group:x:" /etc/group >/dev/null || {
        echo "No existe el grupo lo creamos"
        sudo groupadd "$name_Group"

    }
    return 0
}

validarUsuario(){
  grep "^$name_User:" /etc/passwd >/dev/null 2>/dev/null || { echo "El usuario no existe"; sleep 2s;
  return 1 
  } 
}
#------------------------------------------------main------------------------------------------------
opcion=0
while [ "$opcion" -ne 5 ]; do
    clear
    echo -e "\t\t\t $COLOR_BG_ROJO =================== $COLOR_RESET"
    echo -e "\t\t\t $COLOR_BG_ROJO GESTION DE USUARIOS $COLOR_RESET"
    echo -e "\t\t\t $COLOR_BG_ROJO =================== $COLOR_RESET"
    echo -e "\t\t\t 1. $COLOR_VERDE Crear nuevo usuario $COLOR_RESET"
    echo -e "\t\t\t 2. $COLOR_AZUL Borrar usuario $COLOR_RESET"
    echo -e "\t\t\t 3. $COLOR_AMARILLO Cambiar password usuario $COLOR_RESET"
    echo -e "\t\t\t 4. $COLOR_MAGENTA Añadir a un nuevo grupo a un usuario existente $COLOR_RESET"
    echo -e "\t\t\t 5. --SALIR--"
    echo -n -e "\t\t\t\t ${COLOR_AMARILLO}Opcion:_$COLOR_RESET"
    read opcion

    case $opcion in
        1) crearUsuario ;;
        2) borrarUsuario ;;
        3) cambiarPassword ;;
        4) aniadirGrupo ;;
        5) echo "Saliendo..." ;;
    esac
    read -p "Pulsa enter para salir " enter
    echo "$enter"
done
