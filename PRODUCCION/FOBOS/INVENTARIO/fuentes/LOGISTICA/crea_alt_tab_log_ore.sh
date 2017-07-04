for i in orellana@$1
	do
		echo "Creando gent025 en $i ..."
		dbaccess $i gent025.sql
		echo "Creando rept115 en $i ..."
		dbaccess $i rept115.sql
		echo "Creando rept116 en $i ..."
		dbaccess $i rept116.sql

		echo "Modificando gent031 en $i ..."
		dbaccess $i alt_g31_01.sql

		echo "Modificando rept108 en $i ..."
		dbaccess $i alt_r108_01.sql

		echo "Modificando rept109 en $i ..."
		dbaccess $i alt_r109_01.sql

		echo "Modificando rept110 en $i ..."
		dbaccess $i alt_r110_01.sql

		echo "Modificando rept113 en $i ..."
		dbaccess $i alt_r113_02.sql

		echo "Modificando rept114 en $i ..."
		dbaccess $i alt_r114_01.sql

		echo "Modificando rept116 en $i ..."
		dbaccess $i alt_r116_01.sql

	done
