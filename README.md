# Pasar_tests_MP
Script en Bash que pasa los tests proporcionados por el profesor Andrés Cano Utrera en la asignatura de MP de la UGR.
### Motivaciones
Comprobar los tests manualmente es un trabajo tedioso, cuando haciendo un script se tarda menos que pasando todos los tests en sucesivos proyectos.
### Características
- Muestra el código cuando algún test falla, facilitando así la depuración.
- Manipula correctamente los archivos para que los tests puedan pasarse seguidamente (pasar, corregir y volver a pasar).
- Tiene una opción para seleccionar un intervalo de tests a pasar. Útil cuando solo se quieren comprobar intervalos específicos de tests.
- Puede pasar los tests de integridad. La diferencia frente al script proporcionado por el profesor, es que este sí pasa el comprobador de fugas de memoria Valgrind (pues, en nuestro caso, nos salían los tests de integridad bien con su script y en la corrección se vio que no). Aunque seguramente sea fallo nuestro.
- La interfaz del script que pasa los tests de integridad cuando un test falla usa el comando differ, que puede ser muy difícil de interpretar para alguien novato en este comando.
- Puede ejecutar el script proporcionado por los profesores para crear el zip si todos los tests han salido correctos (o han necesitado comprobación manual).
- Modularizado en funciones y con un código fuente totalmente comentado para una legibilidad alta.
### Capturas
![captura_1](assets/Captura_3.png)
![captura_2](assets/Captura_2.png)
![captura_3](assets/Captura_1.png)
### Uso
Para comenzar a usar el script necesita tener configurados todos las variables en el archivo config.sh. Donde vienen especificadas las distintas opciones que puede realizar el script. Necesita arreglar el archivo proporcionado por los profesores.

Una vez configurado siguiendo las instrucciones de fichero de configuración, puede usarse indefinidamente.

Nota: Muchas veces me ha pasado que he creído un fallo en el script pero estaba en la configuración. Por tanto, revise la configuración dos veces. Tampoco interrumpa la ejecución del script, pues entonces el programa no restaurará el main.cpp para que se puedan volver a pasar y tendrá que volverlo a hacer manualmente antes de poder volverlo a ejecutar.

Una vez configurado y preparado, ejecute: `bash Pasar\ tests.sh`
