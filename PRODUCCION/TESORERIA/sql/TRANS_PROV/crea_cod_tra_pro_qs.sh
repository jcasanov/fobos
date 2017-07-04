for i in aceros@$1 acero_qs@$1
	do
		echo "Creando cxpt006 en $i ..."
		dbaccess $i cxpt006.sql

		echo "Modificando cxpt002 en $i ..."
		dbaccess $i alt_p02_01.sql

	done
