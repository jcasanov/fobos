## BASE: aceros
dbaccess aceros   borrar_tab.sql
dbaccess aceros   crea_tablas_resp.sql
if [ ! "$?" -eq 0 ];
then
	echo "fallo: aceros   crea_tablas_resp.sql"; 
	exit 1
fi

dbaccess aceros   act_r10_01.sql
if [ ! "$?" -eq 0 ];
then
	echo "fallo: aceros   act_r10_01.sql";
	exit 1
fi


## BASE: acero_gc
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


## BASE: acero_qm
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


## BASE: acero_qs
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
