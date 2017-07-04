## $1 = base1
## $2 = servidor_base1
## $3 = compania1
## $4 = localidad1

echo "Ejecutando restaura_itecion ..."

echo " "
time fglgo restaura_ite aceros $1 1 1 | tee restaura_ite_gm.log; date

echo " "
time fglgo restaura_ite acero_gc $1 1 2 | tee restaura_ite_gc.log; date

echo " "
time fglgo restaura_ite acero_qm $1 1 3 | tee restaura_ite_qm3.log; date

echo " "
time fglgo restaura_ite acero_qs $1 1 4 | tee restaura_ite_qs.log; date

echo " "
time fglgo restaura_ite acero_qm $1 1 5 | tee restaura_ite_qm5.log; date

echo " "
echo "Restauracion de tablas terminado OK."
