for i in aceros@$1 acero_gm@$1 acero_gc@$1 acero_qm@$1 acero_qs@$1
	do
		dbaccess $i rept108.sql
		dbaccess $i rept109.sql
		dbaccess $i rept110.sql
		dbaccess $i rept111.sql
		dbaccess $i rept112.sql
		dbaccess $i rept113.sql
	done
