. /acero/envfobos.sh
export ruta=$PWD
export DIR="$HOME/RESPALDO/UIO/"
cd /u/respaldos/BASES/ACERO/QS/
echo 'Copiando la base al respaldo ...'
set `ls -1|tail -1`
cd $DIR
cp /u/respaldos/BASES/ACERO/QS/$1 ./acero_qs.tar.gz
echo "SE CARGARA LA BASE: " $1
dbaccess aceros -qcr borra_qs
echo 'Desempaquetando la base de producción ...'
tar xvfz acero_qs.tar.gz
echo 'Subiendo la base de acero sur ...'
dbimport acero_qs -d datadbs
sleep 4
echo 'Poniendo base de acero sur en modo transaccional...'
ontape -s -U acero_qs
rm -rf acero_qs.exp
dbaccess acero_qs -qcr up_st
cd $ruta
