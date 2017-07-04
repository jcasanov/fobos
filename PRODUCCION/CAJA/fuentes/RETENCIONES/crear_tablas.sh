dbaccess $1 alt_j01_01.sql

dbaccess $1 cajt014.sql
dbaccess $1 cxct008.sql
dbaccess $1 cxct009.sql
dbaccess $1 cajt091.sql
dbaccess $1 srit025.sql

if [ "$2" == "S" ]; then
	export ruta=$PWD

	cd $HOME/PRODUCCION/

	sh pasa_sch $1

	cd $ruta
fi

#dbaccess $1 act_sta.sql
