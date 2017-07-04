# INSERTA ITEM Y JERARQUIAS ENTRE BASES DE GUAYAQUI Y QUITO
. /acero/envfobos.sh
export INSERTA_HOME=$FOBOS_HOME/log/INSERTA_ITEM
. funciones.sh

#echo "MENSAJE DE PRUEBA 1" 2>&1
#echo "MENSAJE DE PRUEBA 2" 2>&1
#exit 1

compara_item;
NUEVOS_UIO=$(getNuevosUIO)
NUEVOS_GYE=$(getNuevosGYE)
CODERR=0


if [ $(($NUEVOS_UIO + $NUEVOS_GYE)) -eq 0 ];
then
	echo "MAESTRO DE ITEM ESTAN IGUALES - NO SE ACTUALIZARON REGISTROS"
else
	echo "TOTAL ITEM PARA INSERTAR EN GYE: " $(getNuevosUIO)
	echo "TOTAL ITEM PARA INSERTAR EN UIO: " $(getNuevosGYE)


	if ! inserta_division; then error_msg "\n  ERROR: NO PUDO INSERTAR DIVISION"; CODERR=1;	fi

	if ! inserta_linea; then 	error_msg "\n  ERROR: NO PUDO INSERTA LINEA"; CODERR=1; fi

	if ! inserta_grupo; then 	error_msg "\n  ERROR: NO PUDO INSERTA GRUPO"; CODERR=1; fi

	if ! inserta_clase; then 	error_msg "\n  ERROR: NO PUDO INSERTA CLASE"; CODERR=1; fi

	if ! inserta_marca; then 	error_msg "\n  ERROR: NO PUDO INSERTA MARCA"; CODERR=1; fi

	if ! inserta_unidad; then 	error_msg "\n  ERROR: NO PUDO INSERTA UNIDAD"; CODERR=1; fi

	if ! inserta_bodega; then 	error_msg "\n  ERROR: NO PUDO INSERTA BODEGA"; CODERR=1; fi

	if ! inserta_capitulo; then 	error_msg "\n  ERROR: NO PUDO INSERTA CAPITULO"; CODERR=1; fi

	if ! inserta_partida; then 	error_msg "\n  ERROR: NO PUDO INSERTA PARTIDA"; CODERR=1; fi

	if ! inserta_item; then 	error_msg "\n  ERROR: NO PUDO INSERTA ITEM"; CODERR=1; fi 

fi
exit $CODERR

