--drop table tmp_bod;
select r02_compania cia, r02_codigo bodega
	from rept002
	where r02_compania   = 1
	  and r02_estado     = 'A'
	  and r02_area       = 'R'
	  and r02_tipo      <> 'S'
	  and r02_localidad  = 5
	into temp tmp_bod;
{--
unload to "stock_marpe_01.unl"
unload to "stock_marpe_02.unl"
unload to "stock_marpe_03.unl"
unload to "stock_marpe_04.unl"
--}
unload to "stock_marpe_05.unl"
select "UIO" local, r72_desc_clase clase, r10_codigo item,
	r10_nombre descripcion, r10_precio_mb prec_vta,
	nvl(sum(r11_stock_act), 0) stock
	from rept010, rept072, rept011
	where r10_compania  = 1
	  and r10_marca     = "MARKPE"
	  and r72_compania  = r10_compania
	  and r72_linea     = r10_linea
	  and r72_sub_linea = r10_sub_linea
	  and r72_cod_grupo = r10_cod_grupo
	  and r72_cod_clase = r10_cod_clase
	  and r11_compania  = r10_compania
	  and r11_item      = r10_codigo
	  and r11_bodega    in(select bodega
				from tmp_bod
				where cia    = r11_compania
				  and bodega = r11_bodega)
	group by 1, 2, 3, 4, 5;
drop table tmp_bod;
