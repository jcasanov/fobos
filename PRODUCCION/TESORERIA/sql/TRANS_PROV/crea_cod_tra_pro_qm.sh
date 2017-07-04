for i in aceros@$1 acero_qm@$1
	do
		echo "Creando cxpt006 en $i ..."
		dbaccess $i cxpt006.sql

		echo "Modificando cxpt002 en $i ..."
		dbaccess $i alt_p02_01.sql

		if [ "$i" == "acero_qm@$1" ]; then
			echo "Cargando datos cod. transf. prov. en $i ...";
			dbaccess $i ins_p06_qm.sql;
			echo "Actualizando datos Bco. transf. prov. en $i ...";
			dbaccess $i act_prov_bco_qm.sql;
		fi

	done
