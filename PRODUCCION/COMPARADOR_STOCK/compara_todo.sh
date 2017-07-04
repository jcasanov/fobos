# COMPARA EL STOCK ENTRE TODAS LAS LOCALIDADES
# TIEMPO ESTIMADO: 11 MINUTOS
. /acero/envfobos.sh

export COMPARADOR_LOG=$FOBOS_HOME/log/COMPARADOR_STOCK
set smtp=ns7.impsat.net.ec

directorio=$COMPARADOR_LOG/`date +%d%b%y`
if [ ! -e "$directorio" ];
then
        mkdir $directorio
fi

stringdb="acero_gm acero_gc acero_qm acero_qs"

> $directorio/compara_todo.log
for i in $stringdb;
do
        time sh compara.sh $i > $directorio/$i.compa.log
	cat $directorio/$i.compa.log >> $directorio/compara_todo.log
done

distintos=`sh suma_distintos.sh $directorio`
echo ""
echo "TOTAL DISTINTOS: "$distintos >> $directorio/compara_todo.log

if [ $distintos != 0 ];
then
	echo "ENVIANDO MENSAJE A CELULAR .."
	echo "TOTAL DISTINTOS: "$distintos |nail -r "stock_$distintos@fobos.com" \
	-s "FOBOS: COMPARADOR STOCK" 95115593@im.movistar.com.ec \
	99038655@im.movistar.com.ec 

	echo "ENVIANDO MAIL CON LOG ADJUNTO .."
	echo "TOTAL DISTINTOS: "$distintos |nail -r "fobos@acerocomercial.com" \
	-s "FOBOS: COMPARADOR STOCK" -a $directorio/compara_todo.log \
	-c "fcosilva@hotmail.com" fsilva@acerocomercial.com npereda@acerocomercial.com 
	#cpaucar@acerocomercial.com emunoz@acerocomercial.com 
	#hsalazar@acerocomercial.com #jebluhm@acerocomercial.com
fi


