#!/bin/bash
#     Copyright (C) 2025 Sergio Castro García
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, version 3 of the License.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program (it is located in LICENSE at the top dir of this program).
#    If not, see <https://www.gnu.org/licenses/>.
#
# Archivo con las funciones auxiliares que necesita el script principal.

# Función que muestra un mensaje de saludo con la licencia.

function SaludoLicencia () {
        echo -e "Pasar tests. Programa que pasa los tests proporcionados por Andrés Cano Utrera.\nCopyright (C) 2025 Sergio Castro García"
        echo -e "\t    This program is free software: you can redistribute it and/or modify
            it under the terms of the GNU General Public License as published by
            the Free Software Foundation, version 3 of the License.
        
            This program is distributed in the hope that it will be useful,
            but WITHOUT ANY WARRANTY; without even the implied warranty of
            MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
            GNU General Public License for more details.
        
            You should have received a copy of the GNU General Public License
            along with this program (it is located in LICENSE at the top dir of this program).
            If not, see <https://www.gnu.org/licenses/>."
        return 0;
}

# Función que comprueba si la configuración es válida.
function ComprobarConfiguracion () {
	(ls $DIR_BASURA && echo 1) || echo 0;
        return 0;
}

# Función que comprueba la línea de inicio. Para ello, devuelve la línea del
# archivo dado (primer parámetro) en el que se encuentra el test nº $2. Empezando
# por la línea $3.
# Parámetros:
#       - 1: Archivo en el que buscar el test.
#       - 2: Nº del test a buscar.
#       - 3: Nº de la primera línea por la que buscar.
# PRE: el archivo $1 debe existir y tener un formato válido.
# PRE: el nº del test a buscar debe encontrarse en el archivo.
# PRE: el nº de la primera línea por la que buscar debe ser correcto.

function EncontrarTest () {
        # Obtengo el máximo de líneas que puedo recorrer.
        local max_lineas=$(wc --lines $1 | cut -d " " -f 1);
        # Obtengo la primera línea en la que se encuentra un test
        local i=$3;
        local encontrado="false";
        # Recorro todos los tests hasta encontrar el que tenga el mismo número que
        # $2
        while (($i<$max_lineas)) && [ "$encontrado" = "false" ]; do
                local numero_test=$(awk "NR==$i" "$1" | cut -d "|" -f 2);
                if [[ $numero_test -eq $2 ]]; then
                        encontrado=true;
                fi

                # La siguiente línea a un test es su salida, por lo que puedo ir de
                # dos en dos para ahorrar iteraciones.
                i=$(($i+2));
        done
	echo $(($i-2));
        return 0;
}
