clear
case $1 in 
4)
	time fglgo recosteo_tra acero_qs idsuio02 1 4 | tee recosteo_tra_qs.log; date
	;;
*)	
	echo "Especifique la localidad correcta"
	exit
	;;
esac

