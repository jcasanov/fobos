## $1 = base1
## $2 = servidor_base1
## $3 = compania1
## $4 = localidad1

echo "Ejecutando respaldos ..."

echo " "
time fglgo respalda_ite aceros $1 1 1 | tee respalda_ite_gm.log; date

echo " "
time fglgo respalda_ite acero_gc $1 1 2 | tee respalda_ite_gc.log; date

echo " "
time fglgo respalda_ite acero_qm $1 1 3 | tee respalda_ite_qm3.log; date

echo " "
time fglgo respalda_ite acero_qs $1 1 4 | tee respalda_ite_qs.log; date

echo " "
time fglgo respalda_ite acero_qm $1 1 5 | tee respalda_ite_qm5.log; date

echo " "
echo "Respaldos de tablas terminado OK."
