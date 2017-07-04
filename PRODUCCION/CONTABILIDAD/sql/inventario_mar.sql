select --+ORDERED
	r10_marca, year(r20_fecing) anio, month(r20_fecing) mes,
	case when month(r20_fecing) = 01 then "ENERO"
	     when month(r20_fecing) = 02 then "FEBRERO"
	     when month(r20_fecing) = 03 then "MARZO"
	     when month(r20_fecing) = 04 then "ABRIL"
	     when month(r20_fecing) = 05 then "MAYO"
	     when month(r20_fecing) = 06 then "JUNIO"
	     when month(r20_fecing) = 07 then "JULIO"
	     when month(r20_fecing) = 08 then "AGOSTO"
	     when month(r20_fecing) = 09 then "SEPTIEMBRE"
	     when month(r20_fecing) = 10 then "OCTUBRE"
	     when month(r20_fecing) = 11 then "NOVIEMBRE"
	     when month(r20_fecing) = 12 then "DICIEMBRE"
	end meses,
	nvl(sum(b13_valor_base), 0) valor
	from rept020, rept010, rept040, ctbt012, ctbt013
	where r20_compania      = 1
	  and r20_localidad    in (3, 5)
	  and year(r20_fecing)  = 2007
	  and r10_compania      = r20_compania
	  and r10_codigo        = r20_item
	  and r40_compania      = r20_compania
	  and r40_localidad     = r20_localidad
	  and r40_cod_tran      = r20_cod_tran
	  and r40_num_tran      = r20_num_tran
	  and b12_compania      = r40_compania
	  and b12_tipo_comp     = r40_tipo_comp
	  and b12_num_comp      = r40_num_comp
	  and b12_estado        = 'M'
	  and b13_compania      = b12_compania
	  and b13_tipo_comp     = b12_tipo_comp
	  and b13_num_comp      = b12_num_comp
	  and b13_cuenta        matches '11400???*'
	group by 1, 2, 3, 4
	order by 2, 3, 1;
