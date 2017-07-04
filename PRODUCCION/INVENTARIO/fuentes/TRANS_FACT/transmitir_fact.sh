. /acero/envfobos.sh
cd $FOBOS_HOME/PRODUCCION/TRAB_EXTRA/FOBOS/INVENTARIO/fuentes/TRANS_FACT
echo ""
echo "INICIO : " $(date)
echo ""
ERROR_MSG=$(time . trans_fact.sh 2>&1)  
AlertGen.sh $? "FOBOS: TRANSMISION FACTURAS FAILED" "TRANS_FACT@acero.com" "ERROR AL TRANSMITIR FACTURAS ENTRE UIO-GYE-SUR \n\n$ERROR_MSG"
echo ""
echo "FIN : " $(date)
echo ""
exit $?
