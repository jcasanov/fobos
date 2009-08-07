echo $HOME

echo "UNLOAD TO '$HOME/$4.unl' "                    >> pedido.sql   
echo "SELECT r17_item, r10_nombre, r17_cantped, "   >> pedido.sql 
echo "       r10_peso, r17_fob, "                   >> pedido.sql
echo "       (r17_cantped * r10_peso) peso_total, " >> pedido.sql
echo "       (r17_cantped * r17_fob) fob_total "    >> pedido.sql
echo "  FROM rept017, rept010 "                     >> pedido.sql 
echo " WHERE r17_compania  = $1 "                   >> pedido.sql
echo "   AND r17_localidad = $2 "                   >> pedido.sql
echo "   AND r17_pedido    = '$3'"                  >> pedido.sql
echo "   AND r17_compania  = r10_compania "         >> pedido.sql
echo "   AND r17_item      = r10_codigo "           >> pedido.sql

dbaccess $5 -qcr pedido.sql

rm -f pedido.sql
