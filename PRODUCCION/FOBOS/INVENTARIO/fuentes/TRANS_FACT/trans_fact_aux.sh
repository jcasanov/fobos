# TRANSMITE FACTURAS PARA CRUZAR CON TR GUAYAQUI, QUITO Y EL SUR
. /acero/envfobos.sh

echo " "
echo "01_trans_fa_tr"
echo " "
dbaccess aceros 01_trans_fa_tr.sql

echo " "
echo "03_trans_fa_tr"
echo " "
dbaccess aceros 03_trans_fa_tr.sql

echo " "
echo "04_trans_fa_tr"
echo " "
dbaccess aceros 04_trans_fa_tr.sql

echo " "
echo "compara_fa_tr"
echo " "
#dbaccess aceros compara_fa_tr.sql
