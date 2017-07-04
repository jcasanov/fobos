echo "CREANDO TABLAS BASE: acero_qs "
echo ""
dbaccess aceros borrar_tab.sql
dbaccess aceros crea_tablas_ace.sql
dbaccess acero_qs borrar_tab.sql
dbaccess acero_qs crea_tablas_resp.sql
if [ ! "$?" -eq 0 ];
then
	echo "fallo: acero_qs crea_tablas_resp.sql";
	exit 1
fi

dbaccess acero_qs act_r10_04.sql
if [ ! "$?" -eq 0 ];
then
	echo "fallo: acero_qs act_r10_01.sql";
	exit 1
fi

exit 0
