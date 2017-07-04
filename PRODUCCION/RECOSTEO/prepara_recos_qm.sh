time sh ej_restaura_tra_qm.sh idsuio01; date
time sh ej_respalda_tra_qm.sh idsuio01; date

#time sh ej_restaura_tra_qm.sh acuiopr; date
#time sh ej_respalda_tra_qm.sh acuiopr; date

anio=`date +%Y`
mes=`date +%m`

time fglgo mayoriza acero_qm idsuio01 1 3 "XX" 2009 1 $anio $mes | tee mayoriza_qm.log; date

dbaccess acero_qm up_sta_tab.sql
if [ ! "$?" -eq 0 ];
then
	echo "fallo: acero_qm up_sta_tab.sql";
	exit 1
fi
