#anio=`date +%Y`
anio=2009
#mes=`date +%m`
mes=12

for i in 1 2 3 4 5 6 7 8 9 10 11 12

	do

		#if [ "$i" -lt "$mes" ]; then

			if [ $i == 1 ]; then
				mes_l="ene"
			fi

			if [ $i == 2 ]; then
				mes_l="feb"
			fi

			if [ $i == 3 ]; then
				mes_l="mar"
			fi

			if [ $i == 4 ]; then
				mes_l="abr"
			fi

			if [ $i == 5 ]; then
				mes_l="may"
			fi

			if [ $i == 6 ]; then
				mes_l="jun"
			fi

			if [ $i == 7 ]; then
				mes_l="jul"
			fi

			if [ $i == 8 ]; then
				mes_l="ago"
			fi

			if [ $i == 9 ]; then
				mes_l="sep"
			fi

			if [ $i == 10 ]; then
				mes_l="oct"
			fi

			if [ $i == 11 ]; then
				mes_l="nov"
			fi

			if [ $i == 12 ]; then
				mes_l="dic"
			fi

			time sh imp_rent.sh $1 $anio $i $mes_l

			mes_f=$i
		#fi

	done

echo "Impuesto a la Renta Generado hasta: "$anio"-"$mes_f" OK"
