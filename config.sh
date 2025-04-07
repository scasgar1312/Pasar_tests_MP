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
#  Fichero de configuración para el programa Pasar test.
#
# Cómo usarlo:
# 	
# 	1. Tras haber terminado el proyecto completamente (asegúrese de que compila correctamente). Copiar
# 	   el proyecto en una carpeta nueva (que va a manipular este script).
# 	
# 	2. Ejecutar el proyecto con NetBeans (usando el botón de «reproducción») y copiar los comandos que realiza
# 	   para ejecutar el programa (los que aparecen en la pestaña «<nombre del proyecto> (Build, run)»).
# 	   Nota importante: si aparece un mensaje de «make[2]: 'dist/Debug/GNU-Linux/boston1' está actualizado.».
# 	   Entonces deberá realizar algún cambio para que aparezcan los comandos de compilación.
# 	   Pues NetBeans no vuelve a compilar si detecta que ya está
# 	   actualizado.
# 	   Tiene que guardarlos en un archivo (omitiendo las salidas de los comandos, solamente los comandos) que
# 	   más adelante deberá indicarle a este programa usando la variable correspondiente.
# 	
# 	3. Modificar el main.cpp eliminando la función main() completamente (el encabezado y todo el código
#          entre las dos llaves de la función). Dejar los include y el resto de código.
#
#   	4. Añadir el código necesario al archivo main.cpp que indican los profesores en el archivo de Markdown
#          sobre cómo ejecutar los tests. También habrá que modificar, siguiendo las instrucciones de mismo
#          documento, algunos tests (por ejemplo, sustituir InspectT() por ToString()).
#
#   	5. Escribir en un archivo cómo debe iniciar el programa la función main() (esto previene
#          por si, en un futuro, tuviéramos que cambiar la declaración del main()). Ejemplo:
#
#          	int main () {
#
#	6. Escribir en un archivo cómo debe cerrar el programa la función main() (esto previene
#	       al programa por si, en un futuro, tuviéramos que cambiar el cierre del main()). Ejemplo:
#
#	   	      return 0;
#	   	      }
#
#	7. Apuntar la ruta absoluta al archivo resultante de la compilación (el ejecutable). Ejemplo:
#
#	   	        $HOME/Escritorio/Borrar./dist/Debug/GNU-Linux/boston-0
#
#	8. Rellenar las variables que vienen a continuación para que el script funcione correctamente.

# Directorio en el que se encuentra el proyecto listo para probar (véanse los pasos a realizar al inicio del programa)
# , no añada la barra al final "/":
PROYECTO="$HOME/Escritorio/sasa"

# Archivo donde vienen las pruebas que se le tienen que pasar:
ARCHIVO_MD="$HOME/Escritorio/TestReport.md"

# Directorio temporal para este script (se puede eliminar tras su uso). No poner la última barra "/".
# Note que no debe existir, si existe, el programa no se ejecutará. Esto es
# una medida de protección para evitar que borre accidentalmente directorios
# con archivos importantes.
# Aviso importante: el directorio y todos los directorios que haya dentro de él serán borrados
# tras la ejecución del programa.
DIR_BASURA="$HOME/Escritorio/basura"

# Archivo main.cpp del proyecto (por defecto es $PROYECTO/src/main.cpp):

MAIN="$PROYECTO/src/main.cpp"

# Archivo con el main.cpp original del proyecto (relleno correctamente siguiendo
# las indicaciones del guion).
MAIN_CORRECTO="/home/tetonala1312/Documentos/MP/Proyectos/Boston1/src/main.cpp"

# Archivo en el que se encuentran los comandos que ejecuta NetBeans para compilar (véanse los pasos a realizar al inicio del programa):
COMPILAR="$HOME/Documentos/MP/script/comandos_todo.sh"

# Archivo en el que se encuentran los comandos que ejecuta NetBeans para compilar solamente el main.cpp. Si no
# se quiere usar esta opción, copie el valor de la anterior variable. Aunque con esta opción la velocidad
# de ejecución de los tests aumenta considerablemente.
COMPILAR_MAIN="$HOME/Documentos/MP/script/comandos.sh"

# Archivo en el que se encuentra la declaración de la función main()
DECLARACION_MAIN="$HOME/Documentos/MP/script/main_inicio.txt"

# Archivo en el que se encuentra el final de la función main().
CIERRE_MAIN="$HOME/Documentos/MP/script/main_cierre.txt"

# Archivo en el que se genera el ejecutable tras ejecutar los comandos de NetBeans
# (especificar la ruta absoluta). Pista: se obtiene en el último comando de compilación de NetBeans:

SALIDA="$PROYECTO/dist/Debug/GNU-Linux/boston1"

# ¿Ejecutar los tests de integridad?: «true» para que se ejecuten y «false» para que no.
# Nota: para pasar los tests de integridad, se deben ejecutar sobre el proyecto
# con el main.cpp original. Pues estos tests tienen por finalidad probar que el main.cpp
# sea el correcto. Por ello, debe especificar una ruta (externa al proyecto) donde
# tenga el main.cpp lleno con el código tal y como lo establezca la práctica.

EJECUTAR_INTEGRIDAD=true
ENTRADAS_Y_SALIDAS_INTEGRIDAD="$PROYECTO/tests"

# Modificar los tests que se van a ejecutar. Para ello, seleccione el primer test que
# quiere que se ejecute y el último. Nota, debe especificar el siguiente al último para
# terminar por el último. Por defecto, los ejecuta todos (menos los de
# integridad). Nota: las comillas son importantes, si no no funciona.
MOD_INICIO=false
MOD_FINAL=false
INICIO_TESTS="39"
FIN_TESTS="40"

# Ejecutar el script de los profesores para crear el zip si se ejecutan todos los tests
# que se hayan seleccionado sin errores.
# Nota: necesita tener la variable MAIN_INTEGRIDAD correctamente establecida para funcionar.
CREATE_ZIP_IF_NO_ERR=true

# Nombre de los scripts de actualizar y crear zip de los profesores (por si cambian los nombres
# en sucesivos proyectos. No poner la última barra en las rutas.
CARPETA_SCRIPTS="$PROYECTO/scripts"
ZIP_SCRIPT="$CARPETA_SCRIPTS/runZipProject.sh"
