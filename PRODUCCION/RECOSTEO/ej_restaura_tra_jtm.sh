## $1 = base1
## $2 = servidor_base1
## $3 = compania1
## $4 = localidad1

echo "Ejecutando restaura transaccion JTM ..."

echo " "
time fglgo restaura_tra acero_gm $1 1 1 | tee restaura_tra_gm.log; date

echo " "
time fglgo restaura_tra acero_gc $1 1 2 | tee restaura_tra_gc.log; date

echo " "
echo "Restauracion de tablas JTM terminado OK."
