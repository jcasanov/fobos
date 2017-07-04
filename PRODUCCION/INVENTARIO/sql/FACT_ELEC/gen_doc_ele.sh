. /acero/envfobos.sh

ruta=$PWD

cd $HOME/PRODUCCION/TRAB_EXTRA/FOBOS/INVENTARIO/sql/FACT_ELEC/

hor_fin=`date +%H`

let hor_ini+=hor_fin+-2

#fec_trab=`date +%D`
fec_trab=`date +%m/%d/%Y`

fec_dir=`date +%g%m%d`

time sh gen_dia.sh $fec_trab $fec_dir T $hor_ini:00 $hor_fin:00 ; date

dirtrab=DocEle_$fec_dir"_"$hor_fin"00".tar.gz

#cont_err=`ls -ltr $HOME/tmp/$dirtrab | cut -f 6 -d" "`
cont_err=`ls -ltr $dirtrab | cut -f 6 -d" "`

hor_i_t=$hor_ini
if [ ${#hor_i_t} == 1 ]; then
	hor_i_t="0"$hor_i_t
fi

asunto="DOC. ELEC. "$fec_trab" - "$hor_i_t":00 - "$hor_fin":00"

firma=`cat $HOME/firma.txt`

arch_err="XML/${dirtrab:0:18}/errores.log"

echo " "

if [ "$cont_err" != "0" ]; then

	echo "Enviando por correo electrónico $dirtrab ..."

	#"$asunto" -a $HOME/tmp/$dirtrab -b npereda@acerocomercial.com \
	echo -e "Los Documentos Electronicos Solictados"$firma | nail -s \
		"$asunto" -a $dirtrab -b npereda@acerocomercial.com \
		cpaucar@acerocomercial.com

	rm -r -f $dirtrab

	echo "Enviado Archivo $dirtrab  OK"

else

	echo -e "No se envió por correo electrónico $dirtrab ..."

	cont_err=`ls -ltr $arch_err | cut -f 6 -d" "`

	if [ "$cont_err" == "0" ]; then

		echo -e "ERROR Documentos Electronicos; NO SE GENERARON" \
			$firma | nail -s "$asunto" npereda@acerocomercial.com

	else

		echo -e "ERROR Documentos Electronicos; NO SE GENERARON" \
			$firma | nail -s "$asunto" -a $arch_err \
			npereda@acerocomercial.com

	fi

	echo "Revisar ERROR en Archivo $dirtrab"

fi

rm -r -f $arch_err

echo " "

cd $ruta
