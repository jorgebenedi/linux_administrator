#!/bin/bash

#-----------------------------------------------Opciones backup----------------------------------------------


backupsTotal() {
  getOrigenDestinoForBackups || return 1
  setVariablesForBackups || return 1
  sudo -S find "$origen_BackupsTotal" \( -type d -o -type f \) -user $USERNAME | cpio -o -v -B > "${destino_BackupsTotal}/backup_total${rename_backupTotal}_${date_backupTotal}.cpio"
}


backupIncremental(){
   getOrigenDestinoForBackups || return 1
   setVariablesForBackups || return 1 
   compare_incremental=$(ls "${destino_BackupsTotal}"/backup_total"${rename_backupTotal}"_*.cpio)
   find $origen_BackupsTotal \( -type d -o -type f \) -user "$USERNAME" -newer "$compare_incremental" | cpio -o -v -B > "${destino_BackupsTotal}""/incremental""${rename_backupTotal}"_"${date_backupTotal}".cpio 

}

#-----------------------------------------------Origen y Destino----------------------------------------------

getOrigenDestinoForBackups(){
    read -p "Introduce el directorio del cual quieres hacer una copia de seguridad: " origen_BackupsTotal
    read -p "Introduce el directorio donde quieres guardar la copia de seguridad: " destino_BackupsTotal
    [ -z $origen_BackupsTotal ] || [ -z $destino_BackupsTotal ] && echo "Alguna de las variables esta vacia, 
    vuelva a intentarlo"
    return 0
}

#-----------------------------------------------Variables----------------------------------------------

setVariablesForBackups(){
    rename_backupTotal=$(echo "$origen_BackupsTotal" | tr "/" "_")
    date_backupTotal=$(date +%d%m%Y-%H:%M)
    return 0
}


#-----------------------------------------------main----------------------------------------------

option=0;
while [ "$option" -ne 3 ]  ; do
echo "backups con cpio"
echo "1. Crear backup de todo el contenido"
echo "2. Backups incremental"
echo "3. Salir"
read option
    case $option in
        1)backupsTotal ;;
        2)backupIncremental ;; 
        3)exit ;;
    esac
done
