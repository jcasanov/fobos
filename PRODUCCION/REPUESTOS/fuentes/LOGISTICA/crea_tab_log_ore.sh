for i in orellana@$1
	do
		echo "Creando rept108 en $i ..."
		dbaccess $i rept108.sql
		echo "Creando rept109 en $i ..."
		dbaccess $i rept109.sql
		echo "Creando rept110 en $i ..."
		dbaccess $i rept110.sql
		echo "Creando rept111 en $i ..."
		dbaccess $i rept111.sql
		echo "Creando rept112 en $i ..."
		dbaccess $i rept112.sql
		echo "Creando rept113 en $i ..."
		dbaccess $i rept113.sql
		echo "Creando rept114 en $i ..."
		dbaccess $i rept114.sql

		echo "Modificando rept095 en $i ..."
		dbaccess $i alt_r95_05.sql

	done