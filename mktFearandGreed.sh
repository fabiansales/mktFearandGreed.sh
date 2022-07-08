#!/bin/bash
#Colours
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

dias=2

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


dependencies

GET https://api.alternative.me/fng/?limit=$dias > get.tmp
total_elementos=$(GET https://api.alternative.me/fng/?limit=$dias | jq -r '.data | length')

echo "Descripcion_Valor_Fecha" > result.tmp 
for array in $(seq 0 $(($total_elementos-1))) ; do
	value_today=$(cat get.tmp  | jq -r ".data | .[$array].value")
	titulo_today=$(cat get.tmp  | jq -r ".data | .[$array].value_classification")
	time_today=$(cat get.tmp | jq -r  ".data | .[$array].timestamp")
	date_converted_today=$(date +'%d.%m.%Y' -d @${time_today})
	if [ $date_converted_today == $(date  +"%d.%m.%Y") ] ; then
		date_converted_today="Hoy/Today"
	fi
	echo "${titulo_today}_${value_today}_${date_converted_today}" >> result.tmp
	#echo -e "$greenColour$titulo_today --> $value_today --  $date_converted_today" | column -t -s 	
done
echo -ne "${greenColour}"
printTable '_' "$(cat result.tmp)"
echo -ne "${endColour}"
rm -f get.tmp result.tmp
tput civis
