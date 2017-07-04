clear
case $1 in 
3)
	time fglgo recosteo_tra acero_qm idsuio01 1 3 | tee recosteo_tra_qm3.log; date
	;;
5)
	time fglgo recosteo_tra acero_qm idsuio01 1 5 | tee recosteo_tra_qm5.log; date
	;;
*)	
	echo "Especifique la localidad correcta"
	exit
	;;
esac

