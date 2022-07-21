#!/bin/bash

# Author: Fabian Sales

#Colours
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"
orangeColour="\033[33m"
lightgreenColour="\e[92m"

dias=4

function ctrl_c(){
        echo -e "\n${redColour}[!] Saliendo...\n${endColour}"
        rm -f get.tmp result.tmp 2>/dev/null
        tput cnorm; exit 1
}

trap ctrl_c INT

function dependencies(){
	tput civis; counter=0
	dependencies_array=(jq)

	echo; for program in "${dependencies_array[@]}"; do
		if [ ! "$(command -v $program)" ]; then
                        echo -e "${redColour}[X]${endColour}${grayColour} $program${endColour}${yellowColour} no está instalado${endColour}"; sleep 1
                        echo -e "\n${yellowColour}[i]${endColour}${grayColour} Instalando...${endColour}"; sleep 1
                        apt install $program -y > /dev/null 2>&1
                        echo -e "\n${greenColour}[V]${endColour}${grayColour} $program${endColour}${yellowColour} instalado${endColour}\n"; sleep 2
                        let counter+=1
                fi
	done
}


function printTable(){

    local -r delimiter="${1}"
    local -r data="$(removeEmptyLines "${2}")"

    if [[ "${delimiter}" != '' && "$(isEmptyString "${data}")" = 'false' ]]
    then
        local -r numberOfLines="$(wc -l <<< "${data}")"

        if [[ "${numberOfLines}" -gt '0' ]]
        then
            local table=''
            local i=1

            for ((i = 1; i <= "${numberOfLines}"; i = i + 1))
            do
                local line=''
                line="$(sed "${i}q;d" <<< "${data}")"

                local numberOfColumns='0'
                numberOfColumns="$(awk -F "${delimiter}" '{print NF}' <<< "${line}")"

                if [[ "${i}" -eq '1' ]]
                then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi

                table="${table}\n"

                local j=1

                for ((j = 1; j <= "${numberOfColumns}"; j = j + 1))
                do
                    table="${table}$(printf '#| %s' "$(cut -d "${delimiter}" -f "${j}" <<< "${line}")")"
                done

                table="${table}#|\n"

                if [[ "${i}" -eq '1' ]] || [[ "${numberOfLines}" -gt '1' && "${i}" -eq "${numberOfLines}" ]]
                then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi
            done

            if [[ "$(isEmptyString "${table}")" = 'false' ]]
            then
                echo -e "${table}" | column -s '#' -t | awk '/^\+/{gsub(" ", "-", $0)}1'
            fi
        fi
    fi
}

function removeEmptyLines(){

    local -r content="${1}"
    echo -e "${content}" | sed '/^\s*$/d'
}

function repeatString(){

    local -r string="${1}"
    local -r numberToRepeat="${2}"

    if [[ "${string}" != '' && "${numberToRepeat}" =~ ^[1-9][0-9]*$ ]]
    then
        local -r result="$(printf "%${numberToRepeat}s")"
        echo -e "${result// /${string}}"
    fi
}

function isEmptyString(){

    local -r string="${1}"

    if [[ "$(trimString "${string}")" = '' ]]
    then
        echo 'true' && return 0
    fi

    echo 'false' && return 1
}

function trimString(){

    local -r string="${1}"
    sed 's,^[[:blank:]]*,,' <<< "${string}" | sed 's,[[:blank:]]*$,,'
}

function helpPanel(){
	echo -e "\n${redColour}[!] Uso: ./$0${endColour}"
	for i in $(seq 1 80); do echo -ne "${redColour}-"; done; echo -ne "${endColour}"
	echo -e "\n\n\t${grayColour}[-d] ${endColour}${yelowColour}Cantidad de dias a revisar (por defecto muestras desde 4 dias atras)${endColour}"
	echo -e "\n\t${grayColour}[-h] ${endColour}${yelowColour}Muestra el panel de ayuda${endColour}\n"
	echo -e "\n\t\t${redColour}Ejemplo: ${endcolour}${grayColour}./$0 -d 8${endColour}\n"
	tput cnorm
}


dependencies ; parameter_counter=0 ; ayuda=0

while getopts "d:h" arg ; do
	case $arg in
		d) dias=$OPTARG; let parameter_counter+=1 ;;
		h) helpPanel; ayuda=1; let  parameter_counter+=1 ;;
	esac
done

if [ $parameter_counter -le 1 ] && [ "$ayuda" = "0" ]; then
	GET https://api.alternative.me/fng/?limit=$dias > get.tmp
	total_elementos=$(GET https://api.alternative.me/fng/?limit=$dias | jq -r '.data | length')

	echo "Descripcion_Valor_Fecha" > result.tmp 
	for array in $(seq 0 $(($total_elementos-1))) ; do
		value_today=$(cat get.tmp  | jq -r ".data | .[$array].value")
		value_color=$(cat get.tmp  | jq -r ".data | .[0].value")
		titulo_today=$(cat get.tmp  | jq -r ".data | .[$array].value_classification")
		case ${titulo_today} in
			"Extreme Fear" )
			color_start_individual="${orangeColour}" ;;
			"Fear" )
			color_start_individual="${yellowColour}" ;;
			"Greed" )
			color_start_individual="${lightgreenColour}" ;;
			"Extreme Greed" )
			color_start_individual="${greenColour}" ;;
		esac
		time_today=$(cat get.tmp | jq -r  ".data | .[$array].timestamp")
		date_converted_today=$(date +'%d.%m.%Y' -d @${time_today})
		if [ $date_converted_today == $(date  +"%d.%m.%Y") ] ; then
			date_converted_today="Hoy/Today"
		fi
		echo "${color_start_individual}${titulo_today}_${value_today}_${date_converted_today}${endColour}" >> result.tmp
		#echo -e "$greenColour$titulo_today --> $value_today --  $date_converted_today" | column -t -s 	
	done
	if [ $value_color -ge 48 ] ; then
		color=${redColour}
	else
		color=${greenColour}
	fi
	echo -ne "${color}"
	printTable '_' "$(cat result.tmp)"
	echo -ne "${endColour}"
	rm -f get.tmp result.tmp
	tput cnorm
#else
#	helpPanel
fi
