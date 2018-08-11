for i in aceros@$1 acero_gm@$1
	do
		echo "Creando rolt070 en $i ..."
		dbaccess $i rolt070.sql
		echo "Creando rolt071 en $i ..."
		dbaccess $i rolt071.sql
		echo "Creando rolt072 en $i ..."
		dbaccess $i rolt072.sql
		echo "Creando rolt073 en $i ..."
		dbaccess $i rolt073.sql

		echo "Creando rolt074 en $i ..."
		dbaccess $i rolt074.sql
		echo "Creando rolt075 en $i ..."
		dbaccess $i rolt075.sql
		echo "Creando rolt076 en $i ..."
		dbaccess $i rolt076.sql
	done
