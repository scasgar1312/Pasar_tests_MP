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
# Versión: 1.1
# Programa que pasa los tests de MP a partir del archivo MarkDown en el que se nos dan los tests que se van a pasar.

source config.sh
source aux.sh
error=false
# Saludo y claúsula de la licencia.
SaludoLicencia

if [ $(ComprobarConfiguracion) = 1 ]; then
	error=true
	echo -e "Ha habido un error en la configuración, terminando la ejecución.\n El directorio de basura existe."
fi

# Establezco los mensajes en caso de que los tests pasen bien o mal
readonly BIEN="\e[32mCORRECTO\e[0m"
readonly MAL="\e[31mINCORRECTO\e[0m"
readonly MENSAJE_ERROR_DE_COMPILACION="\n\e[31mERROR DE COMPILACIÓN, ABORTANDO...\e[0m"

# ------------------------------------- Colores -------------------------------------

readonly FORMATO_SALIDA_OBTENIDA="\e[35m"
readonly FORMATO_MENSAJE_DE_SALIDA="\e[4;6m"
readonly FORMATO_SALIDA_CORRECTA="\e[32m"

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
	
	cp "$DIR_BASURA/main.cpp" "$MAIN"

	cd "$PROYECTO"

	# Variable para dectectar algún error de compilación y detener al programa
	error_de_compilacion=1

	# Ahora sé que desde la primera línea en la que hay un test ($INICIO_TESTS) hasta la anterior a $FIN_TESTS está
	# primero el test a ejecutar y, a continuación, en la siguiente línea, el resultado que debería dar.
	# Por tanto, avanzo la variable de iteración de dos en dos, pues paso de dos a dos líneas debido a que
	# cada test ocupa un total de dos líneas.
	for ((i=$INICIO_TESTS;i<$FIN_TESTS && error_de_compilacion == 1;i=i+2)); do
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

		# Compilo y compruebo si hay un error de compilación. Para
		# terminar el bucle en ese caso.
		if ! $(bash "$COMPILAR" > /dev/null 2> "$DIR_BASURA/error_compilacion") ; then
			error_de_compilacion=0
			cat "$DIR_BASURA/error_compilacion"
			echo -e "$MENSAJE_ERROR_DE_COMPILACION"
			echo -e "Código del test: \e[36m$codigo_a_probar\e[0m"
		else
			# Hago ejecutable la salida.
                	chmod u+x $SALIDA
	
        	        # Restauro el main.cpp original sin cambiar (para que en la siguiente iteración
                	# pueda comenzar de nuevo).
                	cp "$DIR_BASURA/main.cpp" $MAIN

                	# Obtengo la salida que se debería obtener en ese comando. Nótese que la salida está en la
                	# línea siguiente a la del test.
                	n=$i+1

                	# Elimino las comillas, porque en algunos test aparecen comillas en las salidas.
                	salida_correcta="$DIR_BASURA/salida_c_$NUMERO_TEST"
                	awk "NR==$n" "$ARCHIVO_MD" | awk -F '```' '{print $2}' | cut -d  '"' -f 2 > "$salida_correcta"

                	# Obtengo la salida que se obtiene al ejecutar el programa:
                	salida_obtenida="$DIR_BASURA/salida_$NUMERO_TEST"

                	error="false"

                	if ! $($SALIDA &>> "$salida_obtenida"); then
                        	error="true"
                	else
                        	echo "" >> "$salida_obtenida"
                	fi
                	# Si la salida obtenida al ejecutar el archivo es la misma que la que dice el documento
                	# que debe salir, entonces el test lo habrá pasado, si no, el test no lo habrá pasado.

                	if [ "$error" == "false" ]; then
				if cmp -s "$salida_obtenida" "$salida_correcta" ; then
                                	echo -e "\n\t\tResultado de la evaluación: $BIEN"
                        	else
                                	echo -e "\n\t\tResultado de la evaluación: $MAL"
                                	echo -e "\n"$FORMATO_MENSAJE_DE_SALIDA"Código del test:\e[0m $codigo_a_probar"
                                	
					echo -e "\n"$FORMATO_MENSAJE_DE_SALIDA"La salida que se obtiene es:\e[0m"
					
					echo -e -n "$FORMATO_SALIDA_OBTENIDA"
                                	cat "$salida_obtenida"
					echo -e -n "\e[0m"
					
                                	echo -e "\n"$FORMATO_MENSAJE_DE_SALIDA"La salida que se debe obtener es:\e[0m"
                                	
					echo -e -n "$FORMATO_SALIDA_CORRECTA"
					cat "$salida_correcta"
					echo -e -n "\e[0m"
                                	
					err=$(($err+1))
                        	fi
                	else

                        	echo -e "\nEste test puede requerir de comparación manual. A continuación se muestra"
                        	echo -e "la información necesaria."
                        	echo -e "\nCódigo del test: \e[36m$codigo_a_probar\e[0m"
                        	echo -e "\nLa salida que se obtiene es:"

                        	if [ -f "$salida_obtenida" ]; then
                                	cat "$salida_obtenida"
                        	else
                                	echo "La salida ha sido totalmente vacía"
                        	fi

                        	echo -e "\nLa salida que se debe obtener es:"
                        	awk "NR==$n" "$ARCHIVO_MD"
                	fi
		fi	
	done

	if [ "$EJECUTAR_INTEGRIDAD" = "true" ]; then
		echo -e "\n\e[33m--------------------------------- Tests de integridad ---------------------------------\e[0m"

		PALABRA_PARA_MOSTRAR_VALGRIND="Warning"

		# Copio el main.cpp original del usuario (pues los tests de integridad prueban el main.cpp, que
		# debe ser el propuesto por el proyecto).
		cp $MAIN_CORRECTO $MAIN
		
		# Compilo el proyecto con el main correcto.
		bash $COMPILAR

		# Cojo la lista de tests que debo pasar
		lista_de_tests=$(ls "$ENTRADAS_Y_SALIDAS_INTEGRIDAD" | grep -E '.test$')

		# Cojo el número de tests que debo pasar para realizar un bucle
		numero_de_tests=$(echo "$lista_de_tests" | wc --words)

		# Me pongo en la carpeta raíz del proyecto para que pueda coger los tests
		cd "$PROYECTO"

		for((j=1;j<=numero_de_tests;j++)); do
			# Cojo el test con el que voy a trabajar
			test_a_pasar="$ENTRADAS_Y_SALIDAS_INTEGRIDAD/$(echo "$lista_de_tests" | awk "NR==$j")"

			# Cojo lo que tengo que añadir al ejecutar el test
			argumentos_str=$(grep '%%%CALL' "$test_a_pasar" | sed -n '{s/^\s*%%%CALL\s*$/ /; s/.*%%%CALL //; s/^[[:space:]]*//; s/[[:space:]]*$//; s/[[:space:]]\+/ /; p}')
			
			# Cojo los argumentos del string y los paso a un vector para poder manipularlos en la
			# salida correctamente.

			if [ "$(echo "$argumentos_str" | cut -d " " -f 1)" = "" ]; then
				argumentos=("totalmente vacío")
				n_argumentos=1
			else	
				argumentos=($(echo "$argumentos_str" | cut -d " " -f 1))
				n_argumentos=2
			fi

			read -ra argumentos <<< "$argumentos_str"

			# Leo el archivo del que se debe obtener la salida (si lo hay)
			obtener_salida=$(grep '%%%FROMFILE' "$test_a_pasar" | sed -n '{s/^\s*%%%FROMFILE\s*$/ /; s/.*%%%FROMFILE //; s/^[[:space:]]*//; s/[[:space:]]*$//; s/[[:space:]]\+/ /; p}')

			if [[ "$obtener_salida" == "" ]]; then
				obtener_salida="salida estándar"
			fi

			# Establezco el archivo en el que se va a guardar la salida correcta
			archivo_salida_correcta="$DIR_BASURA/salida_correcta_integridad_$j"

			# Obtendo la salida que se debería obtener. Que va desde la línea que contiene %%%OUTPUT
			# hasta el final del archivo. El primer sed me incluye la línea con la propia expreción
			# %%%OUTPUT, por lo que el segundo elimina la primera línea.
			cat $test_a_pasar | sed -n '/%%%OUTPUT/,$p' | sed "1d" > "$archivo_salida_correcta"

			# Elimino las líneas en blanco añadidas al final
			sed -i ':a; /^\s*$/ { $d; N; ba; }; $a\' "$archivo_salida_correcta"

			echo -e "\n--------------------------------- \e[34mTest (integridad) $(printf "%3i" $j)\e[0m ---------------------------------"

			# Establezco el archivo en el que se va a guardar la salida
			archivo_salida="$DIR_BASURA/salida_integridad_$j"

			# Guardo si hay algún error en Valgrind
			error_valgrind=0

			# Opciones de Valgrind
			read -ra opciones_valgrind <<< "--track-origins=yes --leak-check=full --error-exitcode=10 --log-file="$DIR_BASURA/resultado_valgrind_$j.txt""

			cd "$PROYECTO"

			if [[ $n_argumentos -ge 2 ]]; then
				if [[ $obtener_salida == "salida estándar" ]]; then
					if [ "$(echo $argumentos_str | grep "<")" != "" ]; then
						cd $PROYECTO && valgrind ${opciones_valgrind[*]} "$SALIDA" < ${argumentos[2]} &>> "$archivo_salida"
						error_valgrind=$?
					else
						cd $PROYECTO && valgrind ${opciones_valgrind[*]}  "$SALIDA" ${argumentos[*]} &>> "$archivo_salida"
						error_valgrind=$?
					fi
				else
					if [ "$(echo $argumentos_str | grep "<")" != "" ]; then
						valgrind ${opciones_valgrind[*]} "$SALIDA" < ${argumentos[2]}
						error_valgrind=$?
					else
						valgrind ${opciones_valgrind[*]} "$SALIDA" ${argumentos[*]} &>> "$archivo_salida"
						error_valgrind=$?
					fi
					cd $PROYECTO && cat $obtener_salida &>> $archivo_salida 2> /dev/null
				fi
			else
				if [[ $obtener_salida == "salida estándar" ]]; then
                                                cd $PROYECTO && valgrind ${opciones_valgrind[*]} "$SALIDA" &>> $archivo_salida
						error_valgrind=$?
					else
						valgrind ${opciones_valgrind[*]} "$SALIDA"
						error_valgrind=$?
						cd $PROYECTO && cat $obtener_salida &>> $archivo_salida
				fi
			fi
			# Elimino las líneas de sobra en la salida
			sed -i ':a; /^\s*$/ { $d; N; ba; }; $a\' "$archivo_salida"

			echo -e -n "\n\t\tResultado de Valgrind: "
			archivo_valgrind="$DIR_BASURA/resultado_valgrind_$j.txt"
			if [ -f "$archivo_valgrind" ]; then
				if cat "$archivo_valgrind" | grep -q "$PALABRA_PARA_MOSTRAR_VALGRIND" || [ $error_valgrind == 10 ]; then
					echo -e "$MAL"
					echo ""	# Inserto un salto de línea
					cat "$archivo_valgrind"
				else
					echo -e "$BIEN"
				fi
			else
				echo -e "$MAL"
				echo "No hay archivo de salida de Valgrind"
			fi

			if [ "$(cat $archivo_salida_correcta)" = "" ]; then
				echo -e "\nEste test puede requerir de comparación manual. A continuación se muestra"
                        	echo -e "la información necesaria."
                        	echo -e "\nEntrada: \e[36m$argumentos\e[0m"
                        	echo -e "\nLa salida que se obtiene es:"
                        	echo -e "$(echo $salida_obtenida)"
                        	echo -e "\nLa salida que se debe obtener es:"
                        	cat "$test_a_pasar"
			else
				if cmp -s "$archivo_salida" "$archivo_salida_correcta" ; then
					echo -e "\n\t\tResultado de la evaluación: $BIEN"
				else
					echo -e "\n\t\tResultado de la evaluación: $MAL"

					# Normalmente, uno de los argumentos es la salida, luego troceo las palabras de los argumentos
					# e imprimo el contenido de los archivos que haya en las distintas palabras del argumento.
					# A partir de 8 no las sigue buscando, pues no tengo tiempo para mejorar el código y conseguir
					# evitar esta chapuza de solución.
					if [[ $n_argumentos -ge 2 ]]; then
						if [ "$(echo $argumentos_str | grep "<")" != "" ]; then
							echo -e "\nEntrada: \e[36m$(cat ${argumentos[2]})\e[0m"
						else
							echo -e "\nEntrada: "${argumentos[*]}""
							cd $PROYECTO
							for((i=1;i<=$(echo "$argumentos_str" | wc --words);i++)); do
								a_leer="$(echo "$argumentos_str" | cut -d " " -f $i)"
								if [[ -f "$a_leer" && "$a_leer" != "$obtener_salida" ]]; then
									echo -e "\n\e[36m--> Archivo $a_leer:\e[0m"
									echo -n -e "\e[33m"
									cat "$a_leer"
									echo -n -e "\e[0m"
									echo -e "\e[36m--> Fin archivo $a_leer:\e[0m"
								fi
							done
						fi
						echo -e "\n--> "$FORMATO_MENSAJE_SALIDA"La salida que se obtiene es:\e[0m"
						echo -e -n "$FORMATO_SALIDA_OBTENIDA"
						cat "$archivo_salida"
						echo -e -n "\e[0m"
						echo -e "\n--> "$FORMATO_MENSAJE_SALIDA"La salida que se debe obtener es:\e[0m"
						echo -e -n "$FORMATO_SALIDA_CORRECTA"
						cat "$archivo_salida_correcta"
						echo -e -n "\e[0m"
						err=$(($err+1))
					else
						echo -e "\nEntrada: \e[36mliteralmente vacía, se ha ejecutado el programa sin argumentos.\e[0m"
						echo -e "\nLa salida que se obtiene es:"
                                                cat "$archivo_salida"
                                                echo -e "\nLa salida que se debe obtener es:"
                                                cat "$archivo_salida_correcta"
					fi
                        	fi
			fi

			rm "$archivo_salida" "$archivo_salida_correcta"
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
