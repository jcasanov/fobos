time sh ej_restaura_tra_uio.sh acuiopr; date
time sh ej_respalda_tra_uio.sh acuiopr; date

anio=`date +%Y`
mes=`date +%m`

time fglgo mayoriza acero_gm acuiopr 1 1 "LQ" 2009 1 $anio $mes | tee mayoriza_gm.log; date

time fglgo mayoriza acero_qm acuiopr 1 3 "LQ" 2009 1 $anio $mes | tee mayoriza_qm.log; date

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
