if [ "$#" = 0 ]; 
then 
	echo "Especifique la base de datos como parametro" 
	exit
fi
stringdb="acero_gm@ACGYE01 acero_gc@ACGYE01 acero_qm@ACUIO01 acero_qs@ACUIO02"

for i in $stringdb;
do
	a=`echo $i|cut -d"@" -f1`
	if [ "$a" = "$1" ];
	then
		base=$a
		baseserver=$i
	fi
done
if [ "$base" = "" ];
then
	echo "la base es incorrecta"
	exit
fi

if [ -f stock.unl ];
then
        echo "ELIMINANDO ARCHIVO stock.unl"
	echo ""
        rm stock.unl
fi

echo "BASE QUE COMPARA: "$baseserver
echo "---------------------------------"
echo ""

dbaccess $baseserver baja_stock.sql

for j in $stringdb;
do
	b=`echo $j|cut -d"@" -f1`
	if [ "$b" != "$1" ];
	then
		if [ "$b" != "acero_gc" ];
		then
#	 	    echo "COMPARANDO ANTES EN:  "$j
#		    dbaccess $j compara_stock.sql #1> $j.log

		    echo "ACTUALIZANDO EN: "$j
		    dbaccess $j actualiza_stock.sql #2> $j.log

	 	    echo "COMPARANDO DESPUES EN: "$j
		    dbaccess $j compara_stock.sql #1> $j.log
		fi
	fi
done

