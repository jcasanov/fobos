dbaccess $1 borra_car.sql

dbaccess $1 rolt022.sql
dbaccess $1 rolt023.sql
dbaccess $1 rolt024.sql
dbaccess $1 rolt025.sql
dbaccess $1 rolt026.sql
dbaccess $1 rolt027.sql

if [ "$2" == "S" ]; then

	export ruta=$PWD
	cd $HOME/PRODUCCION/;

	sh pasa_sch aceros;

	cd $ruta;

	#dbaccess $1 ins_reg.sql

fi
