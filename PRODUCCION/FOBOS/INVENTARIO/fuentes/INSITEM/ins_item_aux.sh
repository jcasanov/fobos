# INSERTA ITEM Y JERARQUIAS ENTRE BASES DE GUAYAQUI Y QUITO
. /acero/envfobos.sh

echo " "
echo "inserta_division"
echo " "
dbaccess aceros 01_insdiv_ace.sql

echo " "
echo "inserta_linea"
echo " "
dbaccess aceros 02_inslin_ace.sql

echo " "
echo "inserta_grupo"
echo " "
dbaccess aceros 03_insgru_ace.sql

echo " "
echo "inserta_clase"
echo " "
dbaccess aceros 04_inscla_ace.sql

echo " "
echo "inserta_marca"
echo " "
dbaccess aceros 05_insmar_ace.sql

echo " "
echo "inserta_unidad"
echo " "
dbaccess aceros 06_insuni_ace.sql

echo " "
echo "inserta_bodega"
echo " "
dbaccess aceros 07_insbod_ace.sql

echo " "
echo "inserta_capitulo"
echo " "
dbaccess aceros 08_inscap_ace.sql

echo " "
echo "inserta_partidas"
echo " "
dbaccess aceros 09_inspar_ace.sql

echo " "
echo "inserta_item"
echo " "
dbaccess aceros 10_insite_ace.sql

echo " "
echo "compara_item"
echo " "
#dbaccess aceros compara_item.sql
