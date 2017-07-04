time sh ej_restaura_tra_qs.sh idsuio02; date
time sh ej_respalda_tra_qs.sh idsuio02; date

#time sh ej_restaura_tra_qs.sh acuiopr; date
#time sh ej_respalda_tra_qs.sh acuiopr; date

dbaccess acero_qs up_sta_tab.sql
if [ ! "$?" -eq 0 ];
then
	echo "fallo: acero_qs up_sta_tab.sql";
	exit 1
fi
