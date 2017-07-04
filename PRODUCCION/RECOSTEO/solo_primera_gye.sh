time sh crear_tablas_gye.sh | tee crear_tablas_gye.log; date

if [ ! "$?" -eq 0 ];
then
	echo "fallo en $0: crear_tablas_gye.sh"; 
	exit 1
fi


time sh ej_respalda_tra_gye.sh acgyede | tee ej_respalda_tra_gye.log; date

if [ ! "$?" -eq 0 ];
then
	echo "fallo en $0: ej_respalda_tra_gye.sh"; 
	exit 1
fi

dbaccess aceros   up_sta_tab.sql
if [ ! "$?" -eq 0 ];
then
	echo "fallo: aceros   up_sta_tab.sql";
	exit 1
fi

dbaccess acero_gc up_sta_tab.sql
if [ ! "$?" -eq 0 ];
then
	echo "fallo: acero_gc up_sta_tab.sql";
	exit 1
fi

dbaccess acero_qm up_sta_tab.sql
if [ ! "$?" -eq 0 ];
then
	echo "fallo: acero_qm up_sta_tab.sql";
	exit 1
fi

dbaccess acero_qs up_sta_tab.sql
if [ ! "$?" -eq 0 ];
then
	echo "fallo: acero_qs up_sta_tab.sql";
	exit 1
fi
