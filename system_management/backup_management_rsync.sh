#!/bin/bash.


backupTotal(){
    rutasBackup || return 1
    rsync -a -v -z "$origen" "$destino"/"backup_sincronizacion"
}

sincronizado(){
    rutasBackup || return 1
    rsync -a -v -z --delete --backup --backup-dir="$destino"/"backup_sincronizacion"/"borrado" "$origen" "$destino"/"backup_sincronizacion" 2> /tmp/log.log
}

rutasBackup(){
    read -p "Introduce la ruta de origen: " origen
    read -p "Introduce la ruta de destino: " destino

}


opcion=0
while [[ $opcion -ne 3 ]]
do
    
    echo "1.Backup sincronizado"
    echo "2.Sincronización"
    read -p "Enter your input: " opcion
    case $opcion in
      1) backupTotal ;;
      2) sincronizado ;;
      *) echo "opcion invalida...debe ser entre 1 y 5" ;;
    esac
done
