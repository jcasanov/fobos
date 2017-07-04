## $1 = base1
## $2 = servidor_base1
## $3 = compania1
## $4 = localidad1

echo "Ejecutando respaldos UIO ..."

echo " "
time fglgo respalda_tra acero_qm $1 1 3 | tee respalda_tra_qm3.log; date

echo " "
time fglgo respalda_tra acero_qm $1 1 5 | tee respalda_tra_qm5.log; date

echo " "
echo "Respaldos de tablas UIO terminado OK."
