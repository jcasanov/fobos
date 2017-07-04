clear
case $1 in 
1)
	time fglgo recosteo_tra acero_gm acuiopr 1 1 0 "LQ" | tee recosteo_tra_gm.log; date
	;;
2)
	time fglgo recosteo_tra acero_gc acuiopr 1 2 0 "LQ" | tee recosteo_tra_gc.log; date
	;;
3)
	time fglgo recosteo_tra acero_qm acuiopr 1 3 0 "LQ" | tee recosteo_tra_qm3.log; date
	;;
4)
	time fglgo recosteo_tra acero_qs acuiopr 1 4 0 "LQ" | tee recosteo_tra_qs.log; date
	;;
5)
	time fglgo recosteo_tra acero_qm acuiopr 1 5 0 "LQ" | tee recosteo_tra_qm5.log; date
	;;
*)	
	echo "Especifique la localidad correcta"
	exit
	;;
esac

