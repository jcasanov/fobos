update gent021 set g21_tipo = 'C',
				   g21_calc_costo = 'N'
 where g21_cod_tran IN ('AF', 'DF', 'FA');

update gent021 set g21_tipo = 'C',
				   g21_calc_costo = 'S'
 where g21_cod_tran IN ('CL', 'IM');
