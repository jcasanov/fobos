dbaccess $1 borra_sob.sql

dbaccess $1 rolt019.sql
dbaccess $1 rolt020.sql
dbaccess $1 rolt021.sql

if [ "$2" == "S" ]; then

	export ruta=$PWD
	cd $HOME/PRODUCCION/;

	sh pasa_sch aceros;

	cd $ruta;

	dbaccess $1 ins_reg.sql

fi
