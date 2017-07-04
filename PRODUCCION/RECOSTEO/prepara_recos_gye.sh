time sh ej_restaura_tra_gye.sh acgyede; date
time sh ej_respalda_tra_gye.sh acgyede; date

anio=`date +%Y`
mes=`date +%m`

time fglgo mayoriza aceros acgyede 1 1 "LG" 2009 1 $anio $mes | tee mayoriza_gm.log; date

time fglgo mayoriza acero_qm acgyede 1 3 "LG" 2009 1 $anio $mes | tee mayoriza_qm.log; date

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
