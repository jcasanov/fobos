## $1 = base1
## $2 = servidor_base1
## $3 = compania1
## $4 = localidad1

echo "Ejecutando restaura transaccion UIO ..."

echo " "
time fglgo restaura_tra acero_qm $1 1 3 | tee restaura_tra_qm3.log; date

echo " "
time fglgo restaura_tra acero_qm $1 1 5 | tee restaura_tra_qm5.log; date

echo " "
echo "Restauracion de tablas UIO terminado OK."
