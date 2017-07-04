if [ $2 == 1 ]; then
	dbaccess $1 poner_cta_sem.sql
fi
if [ $2 == 2 ]; then
	dbaccess $1 quitar_cta_sem.sql
fi
