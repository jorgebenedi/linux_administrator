#!/bin/bash

    Rojo="\e[31m"
    Verde="\e[32m"
    Amarillo="\e[33m"
    Azul="\e[34m"
    Magenta="\e[35m"
    Cian="\e[36m"
    Blanco="\e[37m"
    reset="\e[0m" 

pedirnombre(){
	echo -n -e "Introduce el nombre del paquete: "; read nombre;
	[ -z "$nombre" ] && { echo "El nombre del paquete no puede estar vacio"; return 1; }
	return 0
}


nuevo_repo_clave(){
	clear
	read -p "Ingrese la URL de descarga de la clave publica: " clave_url
	[ -z "$clave_url" ] && { echo "La URL de la clave pública no puede estar vacía"; return 1; }
	read -p "Ingrese el nombre para la clave: " nombre_clave
	[ -z "$nombre_clave" ] && { echo "El nombre de la clave no puede estar vacio"; return 1; }
	echo "Descargando clave pública..."
	sudo curl -s "$clave_url" | sudo tee /etc/apt/keyrings/$nombre_clave.gpg >/dev/null
	read -p "Ingresa la url del repositorio: " url_Repositorio
    	[ -z "$url_Repositorio" ] && { echo "No puede estar vacio la URL del repositorio"; return 1; }
	echo "Añadiendo nuevo repositorio a /etc/apt/sources.list.d/${nombre_clave}.list"
	echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/${nombre_clave}.gpg] ${url_Repositorio} $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/${nombre_clave}.list
	sudo apt update && echo "Actualizando..." 
	clear && { echo -e "\t\t\tRepositorio añadido correctamente"; sleep 3s; clear; }
} 


instalar_software(){
	clear
	pedirnombre || return 1
	sudo apt update && sudo apt upgrade -y
	sudo apt install $nombre && clear && { echo -e "\t\t ${Rojo}El paquete $nombre ha sido instalado mediante apt${reset}"; sleep 3s; clear; }
}

instalar_software_snap(){
	clear
	pedirnombre || return 1
	sudo apt update && sudo apt upgrade -y
	sudo snap install $nombre && clear && { echo -e "\t\t ${Rojo}El paquete $nombre ha sido instalado mediante snap${reset}"; sleep 3s; clear; }
}


borrar_paquete(){
	clear

	pedirnombre || return 1
		
	apt list --installed | { grep -q "$nombre" && sudo apt remove "$nombre"; clear; } && { echo -e "\t\t ${Rojo}El paquete $nombre ha sido desinstalado mediante remove${reset}"; sleep 3s; clear; } || echo "No se ha encontrado el paquete"
}

buscar_paquete(){
	clear
	pedirnombre || return 1
	apt search $nombre | grep -e "^$nombre.*/" && echo "El paquete $nombre esta disponible para instalar" || echo "El paquete $nombre no esta disponible para instalar"
	#apt search "$nombre" 2>/dev/null | grep -q "$nombre" && echo "El paquete $nombre esta disponible para instalar" || echo "El paquete $nombre no esta disponible para instalar"
}
#Correcto, el comando apt search "$paquete" 
#busca información sobre paquetes disponibles para instalación en los repositorios 
#configurados en tu sistema, no necesariamente paquetes que ya estén instalados.


clear
opcion=0
while [ $opcion -ne 5 ]
do

	echo -e "\t\t\t${Blanco}================================${reset}"
	echo -e "\t\t\t${Rojo} BLACK CODE MANAGEMENT SOFTWARE"
	echo -e "\t\t\t${Blanco}================================${reset}"
	echo ""
	echo -e "\t\t1. Añadir nuevo repositorio y su clave publica"
	echo -e "\t\t2. Instalar paquete software"
	echo -e "\t\t3. Borrar paquete software instalado"
	echo -e "\t\t4. Buscar paquete en los repositorios del sistema por nombre"
	echo -e "\t\t5. Instalar software por snap"
        echo -e "\t\t6. Limpiar pantalla"
	echo -e "\t\t7. Salir"
	read opcion

	case $opcion in
	1)nuevo_repo_clave ;;
	2)instalar_software ;;
	3)borrar_paquete ;;
	4)buscar_paquete ;;
	5)instalar_software_snap ;;
	6)clear ;;
	7)clear && exit ;;
	esac
done