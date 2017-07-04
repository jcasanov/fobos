. /acero/envfobos.sh
export ruta=$PWD
export DIR="$HOME/RESPALDO/UIO/"
cd /u/respaldos/BASES/ACERO/QM/
echo 'Copiando la base al respaldo ...'
set `ls -1|tail -1`
cd $DIR
cp /u/respaldos/BASES/ACERO/QM/$1 ./acero_qm.tar.gz
echo "SE CARGARA LA BASE: " $1
dbaccess aceros -qcr borra_qm
echo 'Desempaquetando la base de producción ...'
tar xvfz acero_qm.tar.gz
echo 'Subiendo la base de quito ...'
dbimport acero_qm -d datadbs
sleep 4
echo 'Poniendo base de quito en modo transaccional...'
ontape -s -U acero_qm
rm -rf acero_qm.exp
dbaccess acero_qm -qcr up_st
cd $ruta
