select year(b12_fec_proceso) anio,
	case when month(b12_fec_proceso) = 01 then "01 ENERO"
	     when month(b12_fec_proceso) = 02 then "02 FEBRERO"
	     when month(b12_fec_proceso) = 03 then "03 MARZO"
	     when month(b12_fec_proceso) = 04 then "04 ABRIL"
	     when month(b12_fec_proceso) = 05 then "05 MAYO"
	     when month(b12_fec_proceso) = 06 then "06 JUNIO"
	     when month(b12_fec_proceso) = 07 then "07 JULIO"
	     when month(b12_fec_proceso) = 08 then "08 AGOSTO"
	     when month(b12_fec_proceso) = 09 then "09 SEPTIEMBRE"
	     when month(b12_fec_proceso) = 10 then "10 OCTUBRE"
	     when month(b12_fec_proceso) = 11 then "11 NOVIEMBRE"
	     when month(b12_fec_proceso) = 12 then "12 DICIEMBRE"
	end mes,
	b12_tipo_comp tipo,
	b12_num_comp num,
	case when b12_origen = 'A'
		then "AUTOMATICO"
		else "MANUAL"
	end origen,
	nvl(sum(b13_valor_base), 0) valor
	from ctbt012, ctbt013
	where b12_compania  = 1
	  and b12_estado    = 'M'
	  and b12_origen    = 'A'
	  and b13_compania  = b12_compania
	  and b13_tipo_comp = b12_tipo_comp
	  and b13_num_comp  = b12_num_comp
	  and b13_cuenta    = '21050101005'
	group by 1, 2, 3, 4, 5
union
select year(b12_fec_proceso) anio,
	case when month(b12_fec_proceso) = 01 then "01 ENERO"
	     when month(b12_fec_proceso) = 02 then "02 FEBRERO"
	     when month(b12_fec_proceso) = 03 then "03 MARZO"
	     when month(b12_fec_proceso) = 04 then "04 ABRIL"
	     when month(b12_fec_proceso) = 05 then "05 MAYO"
	     when month(b12_fec_proceso) = 06 then "06 JUNIO"
	     when month(b12_fec_proceso) = 07 then "07 JULIO"
	     when month(b12_fec_proceso) = 08 then "08 AGOSTO"
	     when month(b12_fec_proceso) = 09 then "09 SEPTIEMBRE"
	     when month(b12_fec_proceso) = 10 then "10 OCTUBRE"
	     when month(b12_fec_proceso) = 11 then "11 NOVIEMBRE"
	     when month(b12_fec_proceso) = 12 then "12 DICIEMBRE"
	end mes,
	b12_tipo_comp tipo,
	b12_num_comp num,
	case when b12_origen = 'A'
		then "AUTOMATICO"
		else "MANUAL"
	end origen,
	nvl(sum(b13_valor_base), 0) valor
	from ctbt012, ctbt013
	where b12_compania  = 1
	  and b12_estado    = 'M'
	  and b12_origen    = 'M'
	  and b13_compania  = b12_compania
	  and b13_tipo_comp = b12_tipo_comp
	  and b13_num_comp  = b12_num_comp
	  and b13_cuenta    = '21050101005'
	group by 1, 2, 3, 4, 5
