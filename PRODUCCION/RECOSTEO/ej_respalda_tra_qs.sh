## $1 = base1
## $2 = servidor_base1
## $3 = compania1
## $4 = localidad1

echo "Ejecutando respaldos SUR ..."

echo " "
time fglgo respalda_tra acero_qs $1 1 4 | tee respalda_tra_qs.log; date

echo " "
echo "Respaldos de tablas SUR terminado OK."
