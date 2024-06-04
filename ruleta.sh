#!/bin/bash
# Description: Mostrar que la casa siempre gana en la ruleta

# Colores
RED='\033[0;31m'
LIGHT_RED='\033[38;5;203m'
GREEN='\033[0;32m'
LIGHT_GREEN='\033[38;5;120m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
PURPLE='\033[0;35m'
TURQUOISE='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m'

# Ctrl + C
function ctrl_c() {
    echo -e "\n\n${RED}Saliendo...${NC}"
    exit 1
}

# Array con las técnicas disponibles
tecnicas=("Martingala" "InverseLabrouchere")

trap ctrl_c INT

# Variables globales
verbose=false
line_break=false

# Función de ayuda
function help() {
    echo -e "${GREEN}Uso: ./ruleta.sh [opciones]${NC}"
    echo -e "\t${YELLOW}-m <dinero>${NC} Cantidad de dinero a apostar"
    echo -e "\t${YELLOW}-t <técnica>${NC} Técnica a utilizar"
    echo -e "\t${YELLOW}-c <cantidad>${NC} Cantidad de dinero a apostar inicialmente"
    echo -e "\t${YELLOW}-a <apuesta>${NC} Apuesta a realizar (par, impar)"
    echo -e "\t${YELLOW}-v${NC} Modo verbose"
    echo -e "\t${YELLOW}-h${NC} Muestra esta ayuda"

    # Mostrar técnicas disponibles
    echo -e "\n${GREEN}Técnicas disponibles:${NC}"
    for tecnica in ${tecnicas[@]}; do
        echo -e "\t - ${YELLOW}${tecnica}${NC}"
    done
}

# Función de la técnica martingala
function martingala() {

    # Si no se ha indicado la apuesta inicial preguntar
    if [ -z $apuesta_inicial ]; then
        echo -n "Apuesta inicial: "
        read apuesta_inicial
    fi

    # Validar apuesta inicial
    if ! [[ $apuesta_inicial =~ ^[0-9]+$ ]]; then
        echo -e "${RED}La apuesta inicial debe ser un número entero${NC}"
        exit 1
    fi

    # Validar que la apuesta inicial no sea mayor que el dinero
    if [ $apuesta_inicial -gt $dinero ]; then
        echo -e "${RED}La apuesta inicial no puede ser mayor al dinero${NC}"
        exit 1
    fi

    # Indicar cantidad de apuesta a la cantidad inicial
    apuesta_cantidad=$apuesta_inicial
    
    # Guardar dinero inicial
    dinero_inicial=$dinero

    # Inicializar el número de jugadas
    jugadas=0

    # Variable para saber si hemos ganado
    exito=false
    
    # Variable para guardar las malas jugadas
    malas_jugadas=""

    # Mientras tengamos dinero
    while [ $dinero -ge $apuesta_cantidad ]; do

        # Aumentar el número de jugadas
        let jugadas++

        # Mostrar dinero restante y cantidad apostada
        if [ $verbose == true ]; then
            echo -e "${GRAY}Dinero restante:${NC} ${YELLOW}$dinero€${NC}"
            echo -e "${GRAY}Apostando${NC} ${YELLOW}$apuesta_cantidad€${NC}\n"
        fi

        # Apostar
        dinero=$((dinero - apuesta_cantidad))
        
        # Tirar la ruleta
        tirada_ruleta=$((RANDOM % 37))

        # Mostrar tirada_ruleta
        if [ $verbose == true ]; then
            echo -e "${BLUE}Ha salido el${NC} ${TURQUOISE}$tirada_ruleta${NC}"
        fi

        # Si ganamos
        if [ $((tirada_ruleta %2)) -eq $apuesta ] && [ $tirada_ruleta -ne 0 ]; then
            # Aumentar el dinero
            dinero=$((dinero + apuesta_cantidad * 2))
            
            # Mostrar mensaje
            if [ $verbose == true ]; then
                echo -e "${GREEN}Ganamos!${NC}\n"
            fi
            
            # Indicar que hemos ganado
            exito=true

            # Salir del bucle
            break
        else 
            # Si perdemos (cuando sale 0, la casa gana)
            apuesta_cantidad=$((apuesta_cantidad * 2))

            if [ $verbose == true ]; then
                echo -e "${RED}Perdimos!${NC}\n"
            fi

            # Guardar mala jugada
            malas_jugadas+="${tirada_ruleta} "
        fi
    done

    # Si hemos perdido
    if [ $exito == false ]; then
        
        # Calcular dinero perdido
        dinero_perdido=$((dinero_inicial - dinero))
        
        # Mostrar mensaje
        echo -e "${RED}Ya no se puede apostar más${NC}"
        echo -e "${RED}Has perdido${NC} ${LIGHT_RED}${dinero_perdido}€${NC}"
        echo -e "${RED}Malas jugadas:${NC} ${BLUE}${malas_jugadas}${NC}"
    else
        echo -e "${GREEN}Has ganado${NC} ${LIGHT_GREEN}${apuesta_inicial}€${NC}"
    fi

    # Mostrar número de jugadas
    echo -e "${GRAY}Número de jugadas:${NC} ${YELLOW}$jugadas${NC}"

    # Mostrar dinero actual
    echo -e "${GRAY}Dinero actual:${NC} ${YELLOW}$dinero€${NC}"
}

# Función de la técnica inverse labrouchere
function inverse_labrouchere() {
    # Secuencia inicial de la técnica
    secuencia_inicial=(1 2 3 4)
    
    # Guardar dinero inicial
    dinero_inicial=$dinero

    # Meta de beneficio
    meta=100

    # Secuencia actual
    secuencia=("${secuencia_inicial[@]}")
    
    # Variable para saber si hemos ganado
    exito=false
    
    # Guardar la meta de dinero a alcanzar
    dinero_meta=$((dinero_inicial + meta))

    # Numero de jugadas
    jugadas=0

    # Mientras tengamos dinero
    while [ $dinero -ge 0 ]; do

        # Aumentar el número de jugadas
        let jugadas++

        # Tirada de la ruleta
        tirada_ruleta=$((RANDOM % 37))
        
        # Calcular la apuesta
        if [ ${#secuencia[@]} -eq 1 ]; then
            # Si solo hay un elemento en la secuencia
            apuesta_cantidad=${secuencia[0]}
        else
            # Si hay más de un elemento en la secuencia
            apuesta_cantidad=$(( ${secuencia[0]} + ${secuencia[-1]} ))
        fi

        # Si la apuesta es mayor que el dinero, salir
        if [ $apuesta_cantidad -gt $dinero ]; then
            break
        fi

        # Mostrar apuesta y dinero restante
        if [ $verbose == true ]; then
            echo -e "${GRAY}Tirada de la ruleta:${NC} ${BLUE}$tirada_ruleta${NC}"
            echo -e "${GRAY}Apuesta:${NC} ${YELLOW}$apuesta_cantidad${NC}"
            echo -e "${GRAY}Dinero restante:${NC} ${YELLOW}$dinero€${NC}"

            # Mostrar secuencia
            echo -ne "${GRAY}Secuencia: (${NC}"
            for (( i=0; i<$((${#secuencia[@]})); i++ )); do
                elemento=${secuencia[$i]}
                
                # Mostrar el elemento
                echo -ne "${YELLOW}${elemento}${NC}"
                
                # Si no es el último elemento, mostrar coma
                if [ $i -ne $((${#secuencia[@]} - 1)) ]; then
                    echo -ne "${GRAY}, ${NC}"
                fi
            done

            # Cerrar paréntesis
            echo -e "${GRAY})${NC}"
        fi
            # Si ganamos
        if [ $((tirada_ruleta %2)) -eq $apuesta ] && [ $tirada_ruleta -ne 0 ]; then 
            # Añadir la apuesta a la secuencia
            secuencia+=($apuesta_cantidad)

            # Aumentar el dinero
            let dinero+=$apuesta_cantidad

            # Mostrar mensaje
            if [ $verbose == true ]; then
                echo -e "${GREEN}Ganamos!${NC}\n"
            fi
        else
            # Eliminar el primer y último elemento de la secuencia
            if [ ${#secuencia[@]} -eq 1 ] || [ ${#secuencia[@]} -eq 2 ] ; then
                # Si solo hay uno o dos elementos en la secuencia, reiniciar la secuencia
                secuencia=("${secuencia_inicial[@]}")
            else
                # Si hay más de dos elementos en la secuencia, eliminar el primer y último elemento
                secuencia=(${secuencia[@]:1:$((${#secuencia[@]}-2))})
            fi

            # Restar la apuesta al dinero
            let dinero-=$apuesta_cantidad

            # Mostrar mensaje
            if [ $verbose == true ]; then
                echo -e "${RED}Perdimos!${NC}\n"
            fi
        fi

        # Si ya hemos obtenido nuestro dinero de meta, salir
        if [ $dinero -ge $dinero_meta ]; then
            exito=true
            break
        fi
    done

    # Si hemos perdido
    if [ $exito == false ]; then
        dinero_perdido=$((dinero_inicial - dinero))
        echo -e "${RED}Ya no se puede apostar más${NC}"
        echo -e "${RED}Has perdido${NC} ${LIGHT_RED}$dinero_perdido€${NC}"
    else
        dinero_ganado=$((dinero - dinero_inicial))
        echo -e "${GREEN}Has ganado${NC} ${LIGHT_GREEN}$dinero_ganado€${NC}"
    fi

    # Mostrar número de jugadas y dinero actual
    echo -e "${GRAY}Número de jugadas:${NC} ${YELLOW}$jugadas${NC}"
    echo -e "${GRAY}Dinero actual:${NC} ${YELLOW}$dinero€${NC}"
}

# Mostrar logo del casino
function logo() {
    echo -e "${GREEN} 
/\$\$\$\$\$\$\$            /\$\$             /\$\$              
| \$\$__  \$\$          | \$\$            | \$\$              
| \$\$  \ \$\$ /\$\$   /\$\$| \$\$  /\$\$\$\$\$\$  /\$\$\$\$\$\$    /\$\$\$\$\$\$ 
| \$\$\$\$\$\$\$/| \$\$  | \$\$| \$\$ /\$\$__  \$\$|_  \$\$_/   |____  \$\$
| \$\$__  \$\$| \$\$  | \$\$| \$\$| \$\$\$\$\$\$\$\$  | \$\$      /\$\$\$\$\$\$\$
| \$\$  \ \$\$| \$\$  | \$\$| \$\$| \$\$_____/  | \$\$ /\$\$ /\$\$__  \$\$
| \$\$  | \$\$|  \$\$\$\$\$\$/| \$\$|  \$\$\$\$\$\$\$  |  \$\$\$\$/|  \$\$\$\$\$\$\$
|__/  |__/ \______/ |__/ \_______/   \___/   \_______/${NC}\n\n"
}

# Opciones
while getopts "m:t:hvc:a:" opt; do
    case $opt in
        m)
            dinero=$OPTARG
            ;;
        t)
            tecnica=$OPTARG
            ;;
        v) 
            verbose=true
            ;;
        c)
            apuesta_inicial=$OPTARG
            ;;
        a)
            apuesta=$OPTARG
            ;;
        h)
            help
            exit 0
            ;;
        *)
            help
            exit 1
            ;;
    esac
done

# Mostrar logo
logo

# Si están todas las condiciones correctas
if [ $dinero ] && [ $apuesta_inicial ] && [ $apuesta ] && [ $tecnica ]; then
    line_break=true
fi

# Si no se ha indicado el dinero preguntar
if [ -z $dinero ]; then
    echo -n "Dinero: "
    read dinero
fi

# Validar dinero
if ! [[ $dinero =~ ^[0-9]+$ ]]; then
    echo -e "${RED}El dinero debe ser un número entero${NC}"
    exit 1
fi

# Si no se ha indicado la apuesta preguntar
if [ -z $apuesta ]; then
    echo -n "Apuesta (par, impar): "
    read apuesta
fi

# Validar apuesta
if [[ $apuesta == [Pp]ar ]]; then
    apuesta=0
elif [[ $apuesta == [Ii]mpar ]]; then
    apuesta=1
else
    echo -e "${RED}Apuesta no válida${NC}"
    echo -e "${RED}Las opciones válidas son:${NC} ${LIGHT_RED}par, impar${NC}"
    exit 1
fi

# Si no se ha indicado la técnica preguntar
if [ -z $tecnica ]; then
    echo -n "Técnica: "
    read tecnica

    # salto de linea
    echo ""
fi

# Convertir técnica a minúsculas
tecnica=$(echo $tecnica | tr '[:upper:]' '[:lower:]')

# Hacer salto de línea si no se preguntó por ningún parámetro
if [ $line_break == true ]; then
    echo ""
fi

# Validar técnica
if [[ $tecnica == martingala ]]; then
    martingala
elif [[ $tecnica == inverselabrouchere ]]; then
    inverse_labrouchere
else
    echo -e "${RED}Técnica no válida${NC}"
    echo -e "${RED}Las opciones válidas son:${NC}"
    for tecnica in ${tecnicas[@]}; do
        echo -e "\t - ${LIGHT_RED}${tecnica}${NC}"
    done
    exit 1
fi
