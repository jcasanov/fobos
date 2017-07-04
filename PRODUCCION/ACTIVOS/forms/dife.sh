for j in actf???_?.per
	do
		echo "/acero/SERMACO/PRODUCCION/ACTIVOS/forms/$j"
		diff $j /acero/SERMACO/PRODUCCION/ACTIVOS/forms/$j
		echo ' '
	done
