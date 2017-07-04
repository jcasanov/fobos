for i in ACTAFIN ANTICIPOS CARGAR_IESS IMPTORENTA UTILIDADES VACACIONES
	do
		echo " "
		echo "-----"
		echo $i
		echo " "
		cd $i
		for j in rolf*.per
			do
				echo $j
				diff $j ../../../forms/$j
				echo ' '
			done
		for j in rolp???.4gl
			do
				echo $j
				diff $j ../../$j
				echo ' '
			done
		cd ..
		echo "-----"
		echo " "
	done
cd ..
