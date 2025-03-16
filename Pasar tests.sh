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
# Fecha: 5/03/2025
# Versión: 1.0
# Programa que pasa los tests de MP a partir del archivo MarkDown en el que se nos dan los tests que se van a pasar.

source config.sh
source aux.sh
error=false
# Saludo y claúsula de la licencia.
SaludoLicencia

if [ $(ComprobarConfiguracion) = 1 ]; then
	error=true
	echo "Ha habido un error en la configuración, terminando la ejecución.\n El directorio de basura existe."
fi

# Creo el directorio para la basura.
mkdir -p $DIR_BASURA

if [ $error = false ]; then
	# Inicio un contador de errores para manejar que se ejecute el script para entregar si
	# no los hay.
	err=0

	# Primero busco el inicio y el fin de los tests en el archivo dado.
	if [ "$MOD_INICIO" = "false" ]; then
		INICIO_TESTS=$(cat $ARCHIVO_MD | awk '/```/ {print NR; exit}');
	else
		INICIO_ITERAR=$(cat $ARCHIVO_MD | awk '/```/ {print NR; exit}')
		INICIO_TESTS=$(EncontrarTest $ARCHIVO_MD $INICIO_TESTS $INICIO_ITERAR)
	fi
	
	if [ "$MOD_FINAL" = "false" ]; then
		FIN_TESTS=$(cat $ARCHIVO_MD | awk '/.Integration_/ {print NR; exit}')
	else
		FIN_TESTS=$(EncontrarTest $ARCHIVO_MD $FIN_TESTS $INICIO_TESTS)
	fi
	
	# Creo una copia del main.cpp, para ello, muevo el archivo main.cpp original al directorio basura, y el que
	# se encuentra en el proyecto es el que se modificará para probar los distintos tests sucesivamente
	# , pues si creo otro main, aunque le cambie el nombre, la compilación no funcionará por los ajustes de Make.
	# Pues intentará compilar el otro main (incluso si se llama hola.cpp) y encontrará que no tiene la
	# configuración necesaria para saber cómo compilarlo.
	cp "$MAIN" "$DIR_BASURA/main.cpp"
	cp "$MAIN_CORRECTO" "$MAIN"
	
	# Compilo todo el proyecto una sola vez para asegurarme de que está todo correctamente compilado y que
	# no haga falta compilar el proyecto entero sucesivamente.
	
	bash $COMPILAR
	
	cp "$DIR_BASURA/main.cpp" "$MAIN"
	
	# Ahora sé que desde la primera línea en la que hay un test ($INICIO_TESTS) hasta la anterior a $FIN_TESTS está
	# primero el test a ejecutar y, a continuación, en la siguiente línea, el resultado que debería dar.
	# Por tanto, avanzo la variable de iteración de dos en dos, pues paso de dos a dos líneas debido a que
	# cada test ocupa un total de dos líneas.

	for ((i=$INICIO_TESTS;i<$FIN_TESTS;i=i+2)); do
		# Inicio la función main().
        	cat "$DECLARACION_MAIN" >> $MAIN
		
		# Obtengo la línea con el test.
		TEST=$(awk "NR==$i" "$ARCHIVO_MD")
		
		# Extraigo el código correspondiente al test y lo añado al main.
		codigo_a_probar=$(echo $TEST | awk -F '```' '{print $2}')
		echo "$codigo_a_probar" >> "$MAIN"
		
		# Cierro el main()
		cat "$CIERRE_MAIN" >> "$MAIN"
		
		# Obtengo el número del test.
        	NUMERO_TEST=$(echo $TEST | cut -d "|" -f 2)
		
		# Muestro el mensaje de test antes de compilar para que los errores de compilación
		# aparezcan debajo de test correspondiente.
		echo -e "\n--------------------------------- \e[34mTest $(printf "%3i" $NUMERO_TEST)\e[0m ---------------------------------"
	
		# Compilo el main()
		bash $COMPILAR_MAIN
	
		# Hago ejecutable la salida.
		chmod u+x $SALIDA
	
		# Restauro el main.cpp original sin cambiar (para que en la siguiente iteración
		# pueda comenzar de nuevo).
		cp "$DIR_BASURA/main.cpp" $MAIN
	
		# Obtengo la salida que se debería obtener en ese comando. Nótese que la salida está en la
		# línea siguiente a la del test.
		n=$i+1
	
		# Elimino las comillas, porque en algunos test aparecen comillas en las salidas.
		SALIDA_CORRECTA="$(awk "NR==$n" "$ARCHIVO_MD" | awk -F '```' '{print $2}' | cut -d  '"' -f 2)"
	
		# Obtengo la salida que se obtiene al ejecutar el programa:
		SALIDA_OBTENIDA=$($SALIDA)
		# Si la salida obtenida al ejecutar el archivo es la misma que la que dice el documento
		# que debe salir, entonces el test lo habrá pasado, si no, el test no lo habrá pasado.
		
		if [ "$SALIDA_CORRECTA" = "" ]; then
			echo -e "\nEste test puede requerir de comparación manual. A continuación se muestra"
			echo -e "la información necesaria."
			echo -e "\nLa salida que se obtiene es:"
        	        echo -e "$(echo $SALIDA_OBTENIDA)"
        	        echo -e "\nLa salida que se debe obtener es:"
			echo -e "$(awk "NR==$n" "$ARCHIVO_MD")"
		else
			if [ "$SALIDA_OBTENIDA" = "$SALIDA_CORRECTA" ]; then
				echo -e "\n\t\tResultado de la evaluación: \e[32mCORRECTO\e[0m"
			else
		                echo -e "\n\t\tResultado de la evaluación: \e[31mINCORRECTO\e[0m"
				echo -e "\nEntrada: \e[36m$codigo_a_probar\e[0m"
				echo -e "\nLa salida que se obtiene es:"
		        	echo -e "$(echo $SALIDA_OBTENIDA)"
		        	echo -e "\nLa salida que se debe obtener es:"
				echo -e "$(echo $SALIDA_CORRECTA)"
				err=$(($err+1))
			fi
		fi
		
	done

	if [ "$EJECUTAR_INTEGRIDAD" = "true" ]; then
		echo -e "\n\e[33m--------------------------------- Tests de integridad ---------------------------------\e[0m"
		# Copio el main.cpp original del usuario (pues los tests de integridad prueban el main.cpp, que
		# debe ser el propuesto por el proyecto).
		cp $MAIN_CORRECTO $MAIN
		
		# Compilo el main.cpp
		bash $COMPILAR

		# Obtengo la lista de tests que se encuentran disponibles para este proyecto.
		lista_de_tests=$(ls "$ENTRADAS_Y_SALIDAS_INTEGRIDAD")
		lista_de_entradas=$(echo "$lista_de_tests" | grep ".b[0-9]in")
		lista_de_salidas=$(echo "$lista_de_tests" | grep ".b[0-9]out")
		max_iteracion=$(echo "$lista_de_entradas" | wc --words)
		
		# Cojo cada entrada y cada salida, que tienen exactamente el mismo nombre, pero uno acabado
		# en «in» y otro acabado en «out». En la práctica, estarán en el mismo puesto que su
		# homólogo en la lista de archivos de entrada y de salida.
	
		for((j=1;j<=max_iteracion;j++)); do
			entrada_test="$ENTRADAS_Y_SALIDAS_INTEGRIDAD/$(echo $lista_de_entradas | cut -d " " -f "$j")"
			salida_test=$(cat "$ENTRADAS_Y_SALIDAS_INTEGRIDAD/$(echo $lista_de_salidas | cut -d " " -f "$j")")
			echo -e "\n--------------------------------- \e[34mTest (integridad) $(printf "%3i" $j)\e[0m ---------------------------------"
			salida_obtenida=$(valgrind --leak-check=full --log-file=$DIR_BASURA/resultado_valgrind_$j.txt "$SALIDA" < "$entrada_test")
			echo -e "\nResultado de Valgrind:"
			cat "$DIR_BASURA/resultado_valgrind_$j.txt"
			echo -e "\nEvaluación de la salida:"
			if [ "$salida_obtenida" = "$salida_test" ]; then
				echo -e "\n\t\tResultado de la evaluación: \e[32mCORRECTO\e[0m"
			else
				echo -e "\n\t\tResultado de la evaluación: \e[31mINCORRECTO\e[0m"
	                	echo -e "\nLa salida que se obtiene es: "
	                	echo -e "$(echo $salida_obtenida)"
	                	echo -e "\nLa salida que se debe obtener es: "
	                	echo -e "$(echo $salida_test)"
				echo -e "\nLa entrada que ha fallado es: \e[36m$entrada_test\e[0m"
				echo -e "\n$entrada_test:"
				cat "$entrada_test"
				err=$(($err+1))
			fi
		done
	fi
	
	# Ejecuto el script para crear el zip si procede (depende de la configuración)
	if [ $err -eq 0 ] && [ "$CREATE_ZIP_IF_NO_ERR" = "true" ]; then
		cp $MAIN_CORRECTO $MAIN
		cd "$CARPETA_SCRIPTS"
		bash $ZIP_SCRIPT
		echo -e "\n Enhorabuena, si está viendo esto, ha superado todos los tests con éxito."
	fi
	
	# Restauro el main original para que se puedan volver a ejecutar los tests.
	cp "$DIR_BASURA/main.cpp" $MAIN
	rm -r "$DIR_BASURA"
fi
