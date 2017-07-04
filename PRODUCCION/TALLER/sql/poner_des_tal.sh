dbaccess $1 alt_t07_01.sql

dbaccess $1 alt_t20_02.sql

dbaccess $1 alt_t21_01.sql

dbaccess $1 alt_t24_01.sql

if [ $2 == 3 ]; then
	dbaccess $1 poner_ref_talt.sql
fi
