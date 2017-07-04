time sh crear_tablas_jtm.sh | tee crear_tablas_jtm.log; date

if [ ! "$?" -eq 0 ];
then
	echo "fallo en $0: crear_tablas_jtm.sh"; 
	exit 1
fi


time sh ej_respalda_tra_jtm.sh idsgye01 | tee ej_respalda_tra_jtm.log; date

if [ ! "$?" -eq 0 ];
then
	echo "fallo en $0: ej_respalda_tra_jtm.sh"; 
	exit 1
fi

dbaccess acero_gm up_sta_tab.sql
if [ ! "$?" -eq 0 ];
then
	echo "fallo: acero_gm up_sta_tab.sql";
	exit 1
fi

dbaccess acero_gc up_sta_tab.sql
if [ ! "$?" -eq 0 ];
then
	echo "fallo: acero_gc up_sta_tab.sql";
	exit 1
fi
