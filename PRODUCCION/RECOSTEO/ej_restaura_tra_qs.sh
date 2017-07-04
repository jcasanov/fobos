## $1 = base1
## $2 = servidor_base1
## $3 = compania1
## $4 = localidad1

echo "Ejecutando restaura transaccion SUR ..."

echo " "
time fglgo restaura_tra acero_qs $1 1 4 | tee restaura_tra_qs.log; date

echo " "
echo "Restauracion de tablas SUR terminado OK."
