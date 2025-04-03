#!/bin/bash

COLOR_RESET="\e[0m"
COLOR_ROJO="\e[31m"
COLOR_AMARILLO="\e[33m"
COLOR_VERDE="\e[32m"

backUpTotal(){
    rutasBackup || return 1
    setVariables || return 1
    tar -c -v -z -f "$destino"/"backupTotal""$name_backup"_"$name_date".tar.gz -g "/tmp/fechas/$name_backup" "$origen" || { echo "Las rutas no coinciden";
        return 1
        }
}

backUpIncremental(){
    rutasBackup || return 1
    setVariables || return 1
    tar -c -v -z -f "$destino"/"backupIncremental""$name_backup"_"$name_date".tar -g "/tmp/fechas/$name_backup" "$origen" || { echo "Las rutas no coinciden";
    return 1
    }
     #tar -u -v -f "$destino"/"backupIncremental""$name_backup"_"$name_date".tar -g "/tmp/fechas/$name_backup" "$origen"
}

rutasBackup(){
    read -p "Introduce la ruta de origen: " origen
    [ -z $origen ]
    read -p "Introduce la ruta de destino: " destino
    [ -z "$origen" ] || [ -z "$destino" ] && { #comprobamos si alguna de las variables esta vacia
		echo -e "${COLOR_ROJO}alguna de las variables se encuentra vacia${COLOR_RESET}"
		sleep 2
		return 1
	}
    setVariables || return 1

}

setVariables(){
    name_backup=$(echo "$origen" | tr "/" "_")
    name_date=$(date +%d%m%Y-%H:%M)    
}

#-------------------------------------------------------------------------------#
#----------------------------- main --------------------------------------------#
#-------------------------------------------------------------------------------#
OPCION=0
while [ "$OPCION" -ne 3 ]; do
	clear
	echo -e "\t\t $COLOR_VERDE BACKUPS CON TAR $COLOR_RESET"
	echo -e "\t\t $COLOR_VERDE --------------- $COLOR_RESET"
	echo -e "\t\t 1. backup total"
	echo -e "\t\t 2. backup incremental"
	echo -e "\t\t 3. == SALIR =="
	echo -n -e "\t\t\t $COLOR_AMARILLO opcion: $COLOR_RESET"
	read OPCION

	case $OPCION in
	1) backUpTotal ;;
	2) backUpIncremental ;;
	3) ;;
	*) echo "opcion incorrecta...." ;;
	esac
done