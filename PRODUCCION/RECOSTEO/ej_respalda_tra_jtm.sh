## $1 = base1
## $2 = servidor_base1
## $3 = compania1
## $4 = localidad1

echo "Ejecutando respaldos JTM ..."

echo " "
time fglgo respalda_tra acero_gm $1 1 1 | tee respalda_tra_gm.log; date

echo " "
time fglgo respalda_tra acero_gc $1 1 2 | tee respalda_tra_gc.log; date

echo " "
echo "Respaldos de tablas JTM terminado OK."
