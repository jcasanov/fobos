time sh ej_restaura_tra_jtm.sh idsgye01; date
time sh ej_respalda_tra_jtm.sh idsgye01; date

#time sh ej_restaura_tra_jtm.sh acgyede; date
#time sh ej_respalda_tra_jtm.sh acgyede; date

anio=`date +%Y`
mes=`date +%m`

time fglgo mayoriza acero_gm idsgye01 1 1 "XX" 2009 1 $anio $mes | tee mayoriza_gm.log; date

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
