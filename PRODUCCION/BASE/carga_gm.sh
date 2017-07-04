. /acero/envfobos.sh
export ruta=$PWD
export DIR="$HOME/RESPALDO/DIARIO/"
cd $DIR
echo "SE CARGARA LA BASE: " $1
dbaccess aceros -qcr borra_gm
echo 'Desempaquetando la base de producción ...'
tar xvfz acero_gm.tar.gz
echo 'Subiendo la base de Guayaquil ...'
dbimport acero_gm -d datadbs
sleep 4
echo 'Poniendo base de Guayaquil en modo transaccional...'
ontape -s -U acero_gm
rm -rf acero_gm.exp
dbaccess acero_gm -qcr up_st
cd $ruta
