
argumentos='< data/crimes2_bis.b1in'

cd /home/tetonala1312/Escritorio/sasa && valgrind --track-origins=yes --leak-check=full --log-file=$HOME/Escritorio/basura/resultado_valgrind_1.txt "/home/tetonala1312/Escritorio/sasa/dist/Debug/GNU-Linux/boston1" $argumentos
