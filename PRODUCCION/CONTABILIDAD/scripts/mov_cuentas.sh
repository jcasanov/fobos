# Script para descargar los movimientos de una cuenta contable
# Parametros:
# --> $1 - vg_codcia
# --> $2 - b12_moneda
# --> $3 - vm_fecha_ini
# --> $4 - vm_fecha_fin
# --> $5 - b13_cuenta
# --> $6 - filtro (T Todos  D Debitos  C Creditos)
# --> $7 - archivo a exportar
# --> $8 - vg_base

echo $HOME

echo "UNLOAD TO '$HOME/$7.unl' "                     >> mov_cuentas.sql   

if [ "$6" = "D" -o "$6" = "T" ]; then
	echo "SELECT b13_fec_proceso, b13_glosa, b13_valor_base, 0 " >> mov_cuentas.sql 
	echo "  FROM ctbt012, ctbt013  "                               >> mov_cuentas.sql 
	echo " WHERE b12_compania  = $1  "                              >> mov_cuentas.sql 
	echo "   AND b12_moneda    = '$2'"                              >> mov_cuentas.sql 
	echo "   AND b12_fec_proceso BETWEEN '$3' AND '$4' "		>> mov_cuentas.sql
	echo "   AND b12_estado    <> 'E' " >> mov_cuentas.sql
	echo "   AND b13_compania  = b12_compania " >> mov_cuentas.sql
	echo "   AND b13_tipo_comp = b12_tipo_comp " >> mov_cuentas.sql
	echo "   AND b13_num_comp  = b12_num_comp " >> mov_cuentas.sql
	echo "   AND b13_cuenta    = '$5' " >> mov_cuentas.sql
	echo "   AND b13_valor_base > 0 " >> mov_cuentas.sql
	echo " ORDER BY b13_fec_proceso " >> mov_cuentas.sql
fi

if [ "$6" = "T" ]; then
	echo " UNION " >> mov_cuentas.sql
fi

if [ "$6" = "C" -o "$6" = "T" ]; then
	echo "SELECT b13_fec_proceso, b13_glosa, 0, (b13_valor_base * (-1)) " >> mov_cuentas.sql 
	echo "  FROM ctbt012, ctbt013  "                               >> mov_cuentas.sql 
	echo " WHERE b12_compania  = $1  "                              >> mov_cuentas.sql 
	echo "   AND b12_moneda    = '$2'"                              >> mov_cuentas.sql 
	echo "   AND b12_fec_proceso BETWEEN '$3' AND '$4' "		>> mov_cuentas.sql
	echo "   AND b12_estado    <> 'E' " >> mov_cuentas.sql
	echo "   AND b13_compania  = b12_compania " >> mov_cuentas.sql
	echo "   AND b13_tipo_comp = b12_tipo_comp " >> mov_cuentas.sql
	echo "   AND b13_num_comp  = b12_num_comp " >> mov_cuentas.sql
	echo "   AND b13_cuenta    = '$5' " >> mov_cuentas.sql
	echo "   AND b13_valor_base < 0 " >> mov_cuentas.sql
	echo " ORDER BY b13_fec_proceso " >> mov_cuentas.sql
fi

dbaccess $8 -qcr mov_cuentas.sql
rm -f mov_cuentas.sql
