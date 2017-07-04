for i in aceros@$1 acero_gm@$1 acero_gc@$1
	do
		echo "Creando cxpt006 en $i ..."
		dbaccess $i cxpt006.sql

		echo "Modificando cxpt002 en $i ..."
		dbaccess $i alt_p02_01.sql

		if [ "$i" == "acero_gm@$1" ]; then
			echo "Cargando datos cod. transf. prov. en $i ...";
			dbaccess $i ins_p06_gm.sql;
			echo "Actualizando datos Bco. transf. prov. en $i ...";
			dbaccess $i act_prov_bco_gm.sql;
		fi

	done
