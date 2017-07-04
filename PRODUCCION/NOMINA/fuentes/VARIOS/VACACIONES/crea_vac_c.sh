dbaccess $1 alt_n47_02.sql
dbaccess $1 alt_n91_01.sql
dbaccess $1 cta_ant_vac.sql

if [ "$2" == "S" ]; then

	export ruta=$PWD
	cd $HOME/PRODUCCION/;

	sh pasa_sch aceros;

	cd $ruta;

fi
