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
			echo -e "\nEntrada: \e[36m$codigo_a_probar\e[0m"
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
		bash $COMPILAR_MAIN

		# Cojo la lista de tests que debo pasar
		lista_de_tests=$(ls "$ENTRADAS_Y_SALIDAS_INTEGRIDAD"| grep -E '.test')

		# Cojo el número de tests que debo pasar para realizar un bucle
		numero_de_tests=$(echo "$lista_de_tests" | wc --words)

		# Me pongo en la carpeta raíz del proyecto para que pueda coger los tests
		cd "$PROYECTO"

		echo "$numero_de_tests"

		for((j=1;j<=numero_de_tests;j++)); do
			# Cojo el test con el que voy a trabajar
			test_a_pasar="$ENTRADAS_Y_SALIDAS_INTEGRIDAD/$(echo "$lista_de_tests" | awk "NR==$j")"

			# Cojo lo que tengo que añadir al ejecutar el test
			argumentos_str=$(cat $test_a_pasar | awk "NR==1" | awk -F "%%%CALL " '{print $2}')
			
			# Cojo los argumentos del string y los paso a un vector para poder manipularlos en la
			# salida correctamente.
			
			argumentos=($(echo "$argumentos_str" | cut -d " " -f 1))
			n_argumentos=2
			
			for((n_argumentos;n_argumentos<=$(echo "$argumentos_str" | wc --words);n_argumentos++)); do
				argumentos[$n_argumentos]=$(echo "$argumentos_str" | cut -d " " -f $n_argumentos)
			done

			# Leo el archivo del que se debe obtener la salida (si lo hay)
			obtener_salida=$(cat $test_a_pasar | awk "NR==1" | awk -F "%%%FROMFILE " '{print $2}')

			if [[ $obtener_salida == "" ]]; then
				obtener_salida="salida estándar"
			fi

			# Obtendo la salida que se debería obtener. Que va desde la línea que contiene %%%OUTPUT
			# hasta el final del archivo. El primer sed me incluye la línea con la propia expreción
			# %%%OUTPUT, por lo que el segundo elimina la primera línea.
			salida_correcta=$(cat $test_a_pasar | sed -n '/%%%OUTPUT/,$p' | sed "1d")

			echo -e "\n--------------------------------- \e[34mTest (integridad) $(printf "%3i" $j)\e[0m ---------------------------------"

			if [[ $obtener_salida == "salida estándar" ]]; then
				if [ "$(echo $argumentos_str | grep "<")" != "" ]; then
					salida_obtenida=$(cd $PROYECTO && valgrind --track-origins=yes --leak-check=full --log-file=$DIR_BASURA/resultado_valgrind_$j.txt "$SALIDA" < ${argumentos[2]})
				else
					salida_obtenida=$(cd $PROYECTO && valgrind --track-origins=yes --leak-check=full --log-file=$DIR_BASURA/resultado_valgrind_$j.txt "$SALIDA" ${argumentos[*]})
				fi
			else
				if [ "$(echo $argumentos_str | grep "<")" != "" ]; then
					valgrind --track-origins=yes --leak-check=full --log-file=$DIR_BASURA/resultado_valgrind_$j.txt "$SALIDA" < ${argumentos[2]}
				else
					valgrind --track-origins=yes --leak-check=full --log-file=$DIR_BASURA/resultado_valgrind_$j.txt "$SALIDA" ${argumentos[*]}
				fi

				salida_obtenida="$(cd $PROYECTO && cat $obtener_salida)"
			fi

			echo -e "\nResultado de Valgrind:"
                        cat "$DIR_BASURA/resultado_valgrind_$j.txt"

			if [ "$salida_obtenida" = "" ]; then
				echo -e "\nEste test puede requerir de comparación manual. A continuación se muestra"
                        	echo -e "la información necesaria."
                        	echo -e "\nEntrada: \e[36m$argumentos\e[0m"
                        	echo -e "\nLa salida que se obtiene es:"
                        	echo -e "$(echo $salida_obtenida)"
                        	echo -e "\nLa salida que se debe obtener es:"
                        	cat "$test_a_pasar"
			else
				if [ "$salida_obtenida" = "$salida_correcta" ]; then
					echo -e "\n\t\tResultado de la evaluación: \e[32mCORRECTO\e[0m"
				else
					echo -e "\n\t\tResultado de la evaluación: \e[31mINCORRECTO\e[0m"

					# Normalmente, uno de los argumentos es la salida, luego troceo las palabras de los argumentos
					# e imprimo el contenido de los archivos que haya en las distintas palabras del argumento.
					# A partir de 8 no las sigue buscando, pues no tengo tiempo para mejorar el código y conseguir
					# evitar esta chapuza de solución.
					if [ "$(echo $argumentos_str | grep "<")" != "" ]; then
						echo -e "\nEntrada: \e[36m$(cat ${argumentos[2]})\e[0m"
					else
						echo -e "\nEntrada:"
						for((l=1;l<=n_argumentos;l++)); do
							echo -e "\e[36m--> Archivo ${argumentos[$l]}:\e[0m"
							cat ${argumentos[$l]}
						done
					fi
					echo -e "\nLa salida que se obtiene es:"
					echo -e "$(echo $salida_obtenida)"
					echo -e "\nLa salida que se debe obtener es:"
					echo -e "$(echo $salida_correcta)"
                                err=$(($err+1))
                        fi

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
