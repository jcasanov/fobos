anio=`date +%Y`
#anio=2010
mes=`date +%m`
#mes=12

for i in 01 02 03 04 05 06 07 08 09 10 11 12

	do

		if [ "$i" -lt "$mes" ]; then

			if [ $i == 01 ]; then
				mes_l="ene"
			fi

			if [ $i == 02 ]; then
				mes_l="feb"
			fi

			if [ $i == 03 ]; then
				mes_l="mar"
			fi

			if [ $i == 04 ]; then
				mes_l="abr"
			fi

			if [ $i == 05 ]; then
				mes_l="may"
			fi

			if [ $i == 06 ]; then
				mes_l="jun"
			fi

			if [ $i == 07 ]; then
				mes_l="jul"
			fi

			if [ $i == 08 ]; then
				mes_l="ago"
			fi

			if [ $i == 09 ]; then
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
		fi

	done

echo "Impuesto a la Renta Generado hasta: "$anio"-"$mes_f" OK"
