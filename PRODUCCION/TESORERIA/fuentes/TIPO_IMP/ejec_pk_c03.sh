dbaccess $1 camb_pk_c03_1.sql

if [ $? != 0 ]; then

	echo "ERROR: En el script camb_pk_c03_1.sql. NO SE EJECUTO"

	exit

else

	echo "Terminado la ejecucion del script camb_pk_c03_1.sql ..."

	echo " "

	echo "Sigue con la ejecucion del script camb_pk_c03_2.sql ..."

fi

dbaccess $1 camb_pk_c03_2.sql

if [ $? != 0 ]; then

	echo "ERROR: En el script camb_pk_c03_2.sql. NO SE EJECUTO"

	exit

else

	echo "Terminado la ejecucion del script camb_pk_c03_2.sql ..."

	echo " "

	echo "Sigue con la ejecucion del script camb_pk_c03_3.sql ..."

fi

dbaccess $1 camb_pk_c03_3.sql

if [ $? != 0 ]; then

	echo "ERROR: En el script camb_pk_c03_3.sql. NO SE EJECUTO"

	exit

fi

echo "Terminado la ejecucion del script camb_pk_c03_3.sql ..."

echo " "

echo "Proceso Terminado OK."
