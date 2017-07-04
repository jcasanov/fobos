if [ $# != 3 ] && [ $# != 4 ] && [ $# != 5 ]; then
        echo -e "Parametros Fijos        : (mm/dd/aaaa) (AAMMDD) (1, 3, 4 o T).\n   Variables Adicionales: hor_ini (hh:mm) y hor_fin (hh:mm)"
        exit
fi

#if [ "$1" == "" ]; then
	#echo "Falta ingresar la fecha del día (mm/dd/aaaa)."
	#exit
#fi

#if [ "$2" == "" ]; then
	#echo "Falta ingresar el directorio (AAMMDD)."
	#exit
#fi

#if [ "$3" == "" ]; then
	#echo "Falta ingresar la localidad (1, 3, 4 o T)."
	#exit
#fi

clear

if [ "$4" == "" ] && [ "$5" == "" ]; then
	echo "La parametros de hor_ini (hh:mm) y hor_fin (hh:mm) son opcionales."
	echo " "
fi

for directorio in FA_ELEC NC_ELEC ND_ELEC GR_ELEC RT_ELEC
	do

		rutatrab=$HOME/tmp/$directorio/
		contenido=`ls -l $rutatrab`

		if [ "$contenido" != "total 0" ]; then
			echo "Eliminando contenido de $rutatrab"
			rm -r -f $rutatrab*.xml
		fi

	done

echo " "
echo "Generando archivos $1 ..."

if [ "$3" == "1" ] || [ "$3" == "T" ]; then
	time fglgo gen_tra_dia acero_gm idsgye01 1 1 $1 $4 $5; date
	echo " "
	echo " "
fi

if [ "$3" == "3" ] || [ "$3" == "T" ]; then
	time fglgo gen_tra_dia acero_qm idsuio01 1 3 $1 $4 $5; date
	echo " "
	echo " "
fi

if [ "$3" == "4" ] || [ "$3" == "T" ]; then
	time fglgo gen_tra_dia acero_qs idsuio02 1 4 $1 $4 $5; date
	echo " "
	echo " "
fi

echo " "
echo "Archivos del $1 generados."
echo " "

hora=""

if [ "$5" != "" ]; then
	hora=_${5:0:2}${5:3:2}
fi

if [ "$4" != "" ] && [ "$hora" == "" ]; then
	hora=_${4:0:2}${4:3:2}
fi

dirtrab=DocEle_$2$hora

rm -rf XML/$dirtrab
mkdir XML/$dirtrab

echo "Moviendo archivos .xml al dir. XML/$dirtrab ..."
echo " "

for directorio in FA_ELEC NC_ELEC ND_ELEC GR_ELEC RT_ELEC
	do

		rutatrab=$HOME/tmp/$directorio/
		contenido=`ls -l $rutatrab`

		if [ "$contenido" != "total 0" ]; then

			if [ "$3" == "1" ] || [ "$3" == "T" ]; then

				arch=$rutatrab*009001*.xml
				encon=`find $rutatrab -name "*009001*" -print`

				if [ "$encon" != "" ]; then
					echo "  Transmitiendo $arch hacia srvgye01:$rutatrab ..."
					#rcp $arch srvgye01:$rutatrab
					echo " "
				fi

			fi

			if [ "$3" == "3" ] || [ "$3" == "T" ]; then

				arch=$rutatrab*004001*.xml
				encon=`find $rutatrab -name "*004001*" -print`

				if [ "$encon" != "" ]; then
					echo "  Transmitiendo $arch hacia srvuio01:$rutatrab ..."
					#rcp $arch srvuio01:$rutatrab
					echo " "
				fi

			fi

			if [ "$3" == "4" ] || [ "$3" == "T" ]; then

				arch=$rutatrab*003001*.xml
				encon=`find $rutatrab -name "*003001*" -print`

				if [ "$encon" != "" ]; then
					echo "  Transmitiendo $arch hacia srvuio02:$rutatrab ..."
					#rcp $arch srvuio02:$rutatrab
					echo " "
				fi

			fi

			echo "  Moviendo contenido de $rutatrab"
			mv $rutatrab*.xml XML/$dirtrab/
			echo " "

		fi

	done

echo " "
echo " "

cd XML/$dirtrab/

grep "°"  *.xml  > errores.log
#grep "&"  *.xml  > errores.log
grep "" *.xml >> errores.log
grep "€" *.xml >> errores.log

ls -ltr errores.log

cont_err=`ls -ltr errores.log | cut -f 6 -d" "`
if [ "$cont_err" != "0" ]; then
	echo " "
	cat errores.log
	echo " "
	echo "El directorio XML/$dirtrab tiene errores para la carga al SRI."
	exit
fi

#rm -rf errores.log

cd ../..

echo "Empaquetando directorio XML/$dirtrab ..."
echo " "

tar cvfz $dirtrab.tar.gz XML/$dirtrab --exclude XML/$dirtrab/errores.log

#echo " "
#echo "Moviendo directorio empaquetado $dirtrab a $HOME/tmp/"

#mv $dirtrab.tar.gz $HOME/tmp/

echo " "
echo "Generación XML/$dirtrab Terminado OK."
