select n48_cod_trab as codigo, n30_nombres as empleado,
	n30_num_doc_id as cedula, n30_fec_jub - 1 units day as fecha_salida,
	n48_val_jub_pat as sueldo,
	case when n30_estado = 'J'
		then "JUBILADO"
	end as estado
	from rolt048, rolt030
	where n48_compania    = 1
	  and n48_cod_liqrol  = 'ME'
	  and n48_ano_proceso = 2011
	  and n48_mes_proceso = 12
	  and n30_compania    = n48_compania
	  and n30_cod_trab    = n48_cod_trab
	order by 2;
