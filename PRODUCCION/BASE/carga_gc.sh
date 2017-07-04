. /acero/envfobos.sh
export ruta=$PWD
export DIR="$HOME/RESPALDO/CENTRO/"
cd $DIR
echo "SE CARGARA LA BASE: " $1
dbaccess aceros -qcr borra_gc
echo 'Desempaquetando la base del Centro ...'
tar xvfz acero_gc.tar.gz
echo 'Subiendo la base del Centro ...'
dbimport acero_gc -d datadbs
sleep 4
echo 'Poniendo base del Centro en modo transaccional...'
ontape -s -U acero_gc
rm -rf acero_gc.exp
dbaccess acero_gc -qcr up_st
cd $ruta
