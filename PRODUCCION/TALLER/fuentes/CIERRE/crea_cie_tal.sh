dbaccess $1 borra_cie.sql

dbaccess $1 alt_t00_01.sql
dbaccess $1 talt042.sql

if [ "$2" == "S" ]; then

	export ruta=$PWD
	cd $HOME/PRODUCCION/;

	sh pasa_sch aceros;

	cd $ruta;

	#dbaccess $1 ins_reg.sql

fi
