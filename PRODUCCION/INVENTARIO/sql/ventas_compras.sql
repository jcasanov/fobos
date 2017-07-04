select extend(r20_fecing, year to month) fecha, r20_cod_tran tp, r20_item item,
	case when r20_cod_tran = 'FA' then
		nvl(sum(r20_cant_ven), 0)
	else
		nvl(sum(r20_cant_ven), 0) * (-1)
	end cantidad,
	case when r20_cod_tran = 'FA' then
		nvl(sum((r20_cant_ven * r20_precio) - r20_val_descto), 0)
	else
		nvl(sum((r20_cant_ven * r20_precio) - r20_val_descto), 0) * (-1)
	end valor, r20_compania cia
	from rept020
	where r20_compania  = 1
	  and r20_localidad = 1
	  and r20_cod_tran  in ('FA', 'DF', 'AF')
	  and date(r20_fecing) between mdy(05, 10, 2006)
                                   and mdy(05, 10, 2007)
	group by 1, 2, 3, 6
union
	select extend(r20_fecing, year to month) fecha, r20_cod_tran tp,
		r20_item item,
		case when r20_cod_tran = 'DC' then
			nvl(sum(r20_cant_ven), 0) * (-1)
		else
			nvl(sum(r20_cant_ven), 0)
		end cantidad,
		case when r20_cod_tran = 'DC' then
			nvl(sum((r20_cant_ven * r20_precio)), 0) * (-1)
		else
			nvl(sum((r20_cant_ven * r20_precio)), 0)
		end valor, r20_compania cia
		from rept020
		where r20_compania  = 1
		  and r20_localidad = 1
		  and r20_cod_tran  in ('CL', 'DC')
		  and date(r20_fecing) between mdy(05, 10, 2006)
                                           and mdy(05, 10, 2007)
		group by 1, 2, 3, 6
	into temp tmp_det;
select year(fecha) anio,
	case when month(fecha) = 01 then "ENE"
	     when month(fecha) = 02 then "FEB"
	     when month(fecha) = 03 then "MAR"
	     when month(fecha) = 04 then "ABR"
	     when month(fecha) = 05 then "MAY"
	     when month(fecha) = 06 then "JUN"
	     when month(fecha) = 07 then "JUL"
	     when month(fecha) = 08 then "AGO"
	     when month(fecha) = 09 then "SEP"
	     when month(fecha) = 10 then "OCT"
	     when month(fecha) = 11 then "NOV"
	     when month(fecha) = 12 then "DIC"
	end mes,
	"GUAYAQUIL" loc, tp,
	case when ((tp = 'FA') or (tp = 'DF') or (tp = 'AF'))
		then "VENTAS"
		else "COMPRAS"
	end tipo, r70_desc_sub linea, r71_desc_grupo grupo,
	r72_cod_clase cod_cla, r72_desc_clase clase, item, r10_nombre desc_item,
	r73_marca marca, round(sum(cantidad), 2) cantidad,
	round(sum(valor), 2) valor
	from tmp_det, rept010, rept070, rept071, rept072, rept073
	where r10_compania  = cia
	  and r10_codigo    = item
	  --and r10_linea     in ('7', '8')		-- SANITARIOS
	  and r10_marca     = 'MILWAU'
	  and r70_compania  = r10_compania
	  and r70_linea     = r10_linea
	  and r70_sub_linea = r10_sub_linea
	  --and r70_sub_linea in ('70', '71', '72', '80', '81', '82')
	  and r71_compania  = r10_compania
	  and r71_linea     = r10_linea
	  and r71_sub_linea = r10_sub_linea
	  and r71_cod_grupo = r10_cod_grupo
	  and r72_compania  = r10_compania
	  and r72_linea     = r10_linea
	  and r72_sub_linea = r10_sub_linea
	  and r72_cod_grupo = r10_cod_grupo
	  and r72_cod_clase = r10_cod_clase
	  and r73_compania  = r10_compania
	  and r73_marca     = r10_marca
	group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
	into temp t1;
drop table tmp_det;
select anio, mes, loc, tipo, linea, grupo, cod_cla, clase, item, desc_item,
	marca,
	case when tipo = "VENTAS"
		then round(sum(cantidad), 2)
		else round(sum(cantidad), 2)
	end cantidad,
	case when tipo = "VENTAS"
		then round(sum(valor), 2)
		else round(sum(valor), 2)
	end valor
	from t1
	group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
	into temp tmp_vta_com;
select count(*) tot_reg_com from tmp_vta_com;
drop table t1;
select r02_codigo bodega
	from rept002
	where r02_compania  = 1
	  and r02_localidad = 1
	  and r02_tipo      = 'F'
	  and r02_area      = 'R'
	  and r02_estado    = 'A'
	into temp tmp_bod;
unload to "stock_gye_01.unl"
	select r11_item item_sto, nvl(sum(r11_stock_act), 0) stock
		from rept011
		where r11_compania = 1
		  and r11_bodega   in (select * from tmp_bod)
		group by 1;
drop table tmp_bod;
unload to "compra_venta_01.unl" select * from tmp_vta_com order by 1, 5, 11;
drop table tmp_vta_com;
