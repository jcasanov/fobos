echo "UNLOAD TO '/tmp/$1.unl' " >> kp.sql
echo "SELECT r17_orden, r17_item, r10_nombre, r17_cantped, r10_peso, r17_fob, " >> kp.sql
echo         " (r17_cantped * r10_peso) peso_total, (r17_cantped * r17_fob) fob_total " >> kp.sql 
echo "  FROM rept017, rept010 "  >> kp.sql
echo " WHERE r17_compania  = 1 " >> kp.sql
echo "   AND r17_localidad = 1 " >> kp.sql
echo "   AND r17_pedido    = '$1' " >> kp.sql
echo "   AND r17_compania  = r10_compania " >> kp.sql
echo "   AND r17_item      = r10_codigo   " >> kp.sql
echo "   ORDER BY r17_orden " >> kp.sql

dbaccess diteca -qcr kp.sql

#rm -f kp.sql
