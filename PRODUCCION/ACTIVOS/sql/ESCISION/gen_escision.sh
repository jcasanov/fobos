if [ "$1" == "" ] || [ "$2" == "" ] || [ "$3" == "" ]; then
	echo "Parametros Incorrectos: Base_1 Base_2 Tipo: G o R"
	exit
fi

if [ "$3" == "G" ]; then
	echo "Generando ECISION en base: $1 ..."
	dbaccess $1 gen_esc_gye.sql
	echo "-----"
	echo "Terminado en base: $1"
	echo "-----"
	echo ""
	echo "Generando ECISION en base: $2 ..."
	dbaccess $2 gen_esc_uio.sql
	echo "-----"
	echo "Terminado en base: $2"
	echo "-----"
fi

if [ "$3" == "R" ]; then
	echo "Reversando ECISION en base: $1 ..."
	dbaccess $1 rev_esc_gye.sql
	echo "-----"
	echo "Reversado en base: $1"
	echo "-----"
	echo ""
	echo "Reversando ECISION en base: $2 ..."
	dbaccess $2 rev_esc_uio.sql
	echo "-----"
	echo "Reversado en base: $2"
	echo "-----"
fi
