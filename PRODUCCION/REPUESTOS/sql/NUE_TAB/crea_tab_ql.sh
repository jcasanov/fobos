for i in aceros@$1 acero_gm@$1 acero_gc@$1 acero_qm@$1 acero_qs@$1
	do
		dbaccess $i rept100.sql
		dbaccess $i rept101.sql
		dbaccess $i rept102.sql
		dbaccess $i rept103.sql
		dbaccess $i rept104.sql
		dbaccess $i rept105.sql
		dbaccess $i rept106.sql
		dbaccess $i rept107.sql
	done

dbaccess aceros@$1   car_r103_01.sql
dbaccess acero_gm@$1 car_r103_01.sql
dbaccess acero_gc@$1 car_r103_02.sql
dbaccess acero_qm@$1 car_r103_03.sql
dbaccess acero_qs@$1 car_r103_04.sql

dbaccess aceros@$1   car_r104_01.sql
dbaccess acero_gm@$1 car_r104_01.sql
dbaccess acero_gc@$1 car_r104_02.sql
dbaccess acero_qm@$1 car_r104_03.sql
dbaccess acero_qs@$1 car_r104_04.sql
