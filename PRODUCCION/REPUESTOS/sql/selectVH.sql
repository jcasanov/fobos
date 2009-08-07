unload to 'informe_komatsu.txt'
select r20_item, r20_cant_ven, DATE(r20_fecing), 
	   r20_cod_tran || '-' || r20_num_tran 
  from rept020
 where r20_compania  = 1
   and r20_localidad = 1
   and r20_cod_tran  = 'FA'
   and r20_linea     = 'KOMAT' 
   and date(r20_fecing) between mdy(04, 01, 2005) and mdy(04, 01, 2006)
 order by 4 asc
