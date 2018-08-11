if [ "$1" == "" ] || [ "$2" == "" ]; then
	echo "Parametros Incorrectos: servidor_base Tipo: G o R"
	exit
fi


if [ "$2" == "G" ]; then

	echo "Modificando estructura ZONA DE COBRO en servidor: $1 ..."

	for i in aceros@$1 acero_gm@$1 acero_gc@$1 acero_qm@$1 acero_qs@$1 #12
	#for i in aceros@$1 acero_gm@$1 acero_gc@$1 #1 G
	#for i in aceros@$1 acero_qm@$1 #1 U
	#for i in aceros@$1 acero_qs@$1 #1 S
		do

			echo "  Generando en Base $i ..."
			dbaccess $i alt_z06_01.sql

			if [ "$i" == "acero_qm@$1" ]; then
				dbaccess $i alt_trn_uio.sql
			fi

			dbaccess $i alt_z22_01.sql
			dbaccess $i alt_z24_01.sql
			echo "  Terminado en Base $i ..."
			echo " ----------------------------- "
			echo " "

		done

	echo "Modificacion estructura terminada OK."
fi


if [ "$2" == "R" ]; then

	echo "Reversando estructura ZONA DE COBRO en servidor: $1 ..."

	for i in aceros@$1 acero_gm@$1 acero_gc@$1 acero_qm@$1 acero_qs@$1 #12
	#for i in aceros@$1 acero_gm@$1 acero_gc@$1 #1 G
	#for i in aceros@$1 acero_qm@$1 #1 U
	#for i in aceros@$1 acero_qs@$1 #1 S
		do

			echo "  Reversando en Base $i ..."
			dbaccess $i des_alt_z.sql

			if [ "$i" == "acero_qm@$1" ]; then
				dbaccess $i des_alt_trn.sql
			fi
			echo "  Reversado en Base $i ..."
			echo " ----------------------------- "
			echo " "

		done

	echo "Reversion de estructura terminada OK."
fi
