clear
case $1 in 
1)
	time fglgo recosteo_tra acero_gm idsgye01 1 1 | tee recosteo_tra_gm.log; date
	;;
2)
	time fglgo recosteo_tra acero_gc idsgye01 1 2 | tee recosteo_tra_gc.log; date
	;;
*)	
	echo "Especifique la localidad correcta"
	exit
	;;
esac

