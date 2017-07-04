for i in aceros@$1 acero_gm@$1 acero_gc@$1 acero_qm@$1 acero_qs@$1
	do
		echo "Creando ctbt017 en $i ..."
		dbaccess $i ctbt017.sql

		if [ "$i" == "acero_qm@$1" ]; then
			echo "Cargando nuevas cuentas en $i ...";
			dbaccess $i subir_b17_qm.sql;
		fi
	done
