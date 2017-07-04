echo "CREANDO TABLAS BASE: acero_qm "
echo ""
dbaccess aceros borrar_tab.sql
dbaccess aceros crea_tablas_ace.sql
dbaccess acero_qm borrar_tab.sql
dbaccess acero_qm crea_tablas_resp.sql
if [ ! "$?" -eq 0 ];
then
	echo "fallo: acero_qm crea_tablas_resp.sql";
	exit 1
fi

dbaccess acero_qm act_r10_03.sql
if [ ! "$?" -eq 0 ];
then
	echo "fallo: acero_qm act_r10_01.sql";
	exit 1
fi
