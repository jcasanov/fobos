dbaccess $1 ctbt044.sql;
dbaccess $1 ctbt045.sql;
dbaccess $1 ins_iva_otros.sql;

if [ "$2" == "S" ]; then

	cp libp*gl $HOME/PRODUCCION/LIBRERIAS/fuentes/;

	export ruta=$PWD
	cd $HOME/PRODUCCION/;

	sh pasa_sch aceros;

	cd LIBRERIAS/fuentes/;

	sh copia;

	cd $ruta;

fi
