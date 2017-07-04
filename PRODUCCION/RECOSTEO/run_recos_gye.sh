clear
case $1 in 
1)
	time fglgo recosteo_tra aceros acgyede 1 1 0 "LG" | tee recosteo_tra_gm.log; date
	;;
2)
	time fglgo recosteo_tra acero_gc acgyede 1 2 0 "LG" | tee recosteo_tra_gc.log; date
	;;
3)
	time fglgo recosteo_tra acero_qm acgyede 1 3 0 "LG" | tee recosteo_tra_qm3.log; date
	;;
4)
	time fglgo recosteo_tra acero_qs acgyede 1 4 0 "LG" | tee recosteo_tra_qs.log; date
	;;
5)
	time fglgo recosteo_tra acero_qm acgyede 1 5 0 "LG" | tee recosteo_tra_qm5.log; date
	;;
*)	
	echo "Especifique la localidad correcta"
	exit
	;;
esac

