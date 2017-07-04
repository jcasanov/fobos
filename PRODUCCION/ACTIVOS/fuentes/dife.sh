for j in actp???.4gl
	do
		echo "/acero/SERMACO/PRODUCCION/ACTIVOS/fuentes/$j"
		diff $j /acero/SERMACO/PRODUCCION/ACTIVOS/fuentes/$j
		echo ' '
	done
