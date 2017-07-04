time sh crear_tablas_qs.sh | tee crear_tablas_qs.log; date

if [ ! "$?" -eq 0 ];
then
	echo "fallo en $0: crear_tablas_qs.sh"; 
	exit 1
fi


time sh ej_respalda_tra_qs.sh idsuio02 | tee ej_respalda_tra_qs.log; date

if [ ! "$?" -eq 0 ];
then
	echo "fallo en $0: ej_respalda_tra_qs.sh"; 
	exit 1
fi

dbaccess acero_qs up_sta_tab.sql
if [ ! "$?" -eq 0 ];
then
	echo "fallo: acero_qs up_sta_tab.sql";
	exit 1
fi
