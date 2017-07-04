select n30_cod_trab as codigo,
	n30_num_doc_id as identificacion,
	n30_nombres as empleado,
	nvl(n30_fecha_reing, n30_fecha_ing) as fecha_ing,
	case when trunc((((today - nvl(n30_fecha_reing, n30_fecha_ing)) + 1) /
		 n90_dias_anio), 0) > 0
		then lpad(trunc((((today - nvl(n30_fecha_reing, n30_fecha_ing))
			 + 1) / n90_dias_anio),	0), 2, 0)
		else ""
	end || 
	case when trunc((((today - nvl(n30_fecha_reing, n30_fecha_ing)) + 1) /
		 n90_dias_anio), 0) = 1
		then " Año "
	     when trunc((((today - nvl(n30_fecha_reing, n30_fecha_ing)) + 1) /
		 n90_dias_anio), 0) > 1
		then " Años "
		else ""
	end ||
	case when trunc(mod(((today - nvl(n30_fecha_reing, n30_fecha_ing))
			 + 1), n90_dias_anio) /	n00_dias_mes, 0) > 0
		then case when (mod(mod(((today - nvl(n30_fecha_reing,
			 n30_fecha_ing)) + 1),
			n90_dias_anio), n00_dias_mes) = 0)
		     or not ((trunc((((today - nvl(n30_fecha_reing,
				n30_fecha_ing)) + 1) / n90_dias_anio), 0) > 0)
			or (trunc(mod(((today - nvl(n30_fecha_reing,
				n30_fecha_ing)) + 1), n90_dias_anio) /
				n00_dias_mes, 0) > 0))
				then "y "
				else ""
			end ||
			lpad(trunc(mod(((today - nvl(n30_fecha_reing,
				n30_fecha_ing)) + 1), n90_dias_anio) /
				n00_dias_mes, 0), 2, 0)
		else ""
	end ||
	case when trunc(mod(((today - nvl(n30_fecha_reing, n30_fecha_ing))
				+ 1), n90_dias_anio) / n00_dias_mes, 0) = 1
	 	then " Mes "
	     when trunc(mod(((today - nvl(n30_fecha_reing, n30_fecha_ing))
				+ 1), n90_dias_anio) / n00_dias_mes, 0) > 1
	 	then " Meses "
		else ""
	end ||
	case when mod(mod(((today - nvl(n30_fecha_reing, n30_fecha_ing))
				+ 1), n90_dias_anio), n00_dias_mes) > 0
		then case when (trunc((((today - nvl(n30_fecha_reing,
				n30_fecha_ing)) + 1) / n90_dias_anio), 0) > 0)
			or (trunc(mod(((today - nvl(n30_fecha_reing,
				n30_fecha_ing)) + 1), n90_dias_anio) /
				n00_dias_mes, 0) > 0)
				then "y "
				else ""
			end ||
			lpad(mod(mod(((today - nvl(n30_fecha_reing,
				n30_fecha_ing)) + 1), n90_dias_anio),
				n00_dias_mes), 2, 0)
		else ""
	end ||
	case when mod(mod(((today - nvl(n30_fecha_reing, n30_fecha_ing)) + 1),
			n90_dias_anio), n00_dias_mes) = 1
		then " Día"
	     when mod(mod(((today - nvl(n30_fecha_reing, n30_fecha_ing)) + 1),
			n90_dias_anio), n00_dias_mes) > 1
		then " Días"
		else ""
	end as tiempo,
	lpad(((today - nvl(n30_fecha_reing, n30_fecha_ing)) + 1), 5, 0) dias,
	case when n30_estado = 'A' then "ACTIVO"
	     when n30_estado = 'I' then "INACTIVO"
	     when n30_estado = 'J' then "JUBILADO"
	end as estado
	from rolt030, rolt090, rolt000
	where n30_compania = 1
	  and n90_compania = n30_compania
	  and n00_serial   = n90_compania
	order by 6 desc, 3 asc;
