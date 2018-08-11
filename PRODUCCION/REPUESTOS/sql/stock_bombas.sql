unload to "stock_bombas.unl"
select r11_item, r10_nombre, r10_marca, nvl(sum(r11_stock_act), 0) valor_stock
	from rept010, rept011
	where r10_compania  = 1
	  and r10_estado    = 'A'
	  and r10_linea     = '2'
	  and r10_sub_linea = '22'
	  and r10_cod_grupo between '220' and '227'
	  and r10_marca     in ('GRUNDF', 'MARKPE')
	  and r11_compania  = r10_compania
	  and r11_bodega    in (select r02_codigo from rept002
					where r02_compania  = 1
					  and r02_tipo     <> 'S'
					  and r02_area      = 'R')
	  and r11_item      = r10_codigo
	group by 1, 2, 3
	order by 1
