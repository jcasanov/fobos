time sh crear_tablas_qm.sh | tee crear_tablas_qm.log; date

if [ ! "$?" -eq 0 ];
then
	echo "fallo en $0: crear_tablas_qm.sh"; 
	exit 1
fi


time sh ej_respalda_tra_qm.sh idsuio01 | tee ej_respalda_tra_qm.log; date

if [ ! "$?" -eq 0 ];
then
	echo "fallo en $0: ej_respalda_tra_qm.sh"; 
	exit 1
fi

dbaccess acero_qm up_sta_tab.sql
if [ ! "$?" -eq 0 ];
then
	echo "fallo: acero_qm up_sta_tab.sql";
	exit 1
fi
