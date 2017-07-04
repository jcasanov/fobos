echo "CREANDO TABLAS BASE: acero_gm "
echo ""
dbaccess aceros borrar_tab.sql
dbaccess aceros crea_tablas_ace.sql
dbaccess acero_gm borrar_tab.sql
dbaccess acero_gm crea_tablas_resp.sql
if [ ! "$?" -eq 0 ];
then
	echo "fallo: acero_gm crea_tablas_resp.sql"; 
	exit 1
fi

dbaccess acero_gm act_r10_01.sql
if [ ! "$?" -eq 0 ];
then
	echo "fallo: acero_gm act_r10_01.sql";
	exit 1
fi


echo "CREANDO TABLAS BASE: acero_gc "
echo ""
dbaccess acero_gc borrar_tab.sql
dbaccess acero_gc crea_tablas_resp.sql
if [ ! "$?" -eq 0 ];
then
	echo "fallo: acero_gc crea_tablas_resp.sql";
	exit 1
fi

dbaccess acero_gc act_r10_02.sql
if [ ! "$?" -eq 0 ];
then
	echo "fallo: acero_gc act_r10_01.sql";
	exit 1
fi
