select SUBSTR(r19_cod_tran,1,2) COD,  r19_num_tran TRAN, r19_nomcli[1,20],
         r19_tot_neto -	(r19_tot_bruto - r19_tot_dscto) iva,
         date(r19_fecing) fecha
	from rept019
	where r19_cod_tran in ('FA','DF')
	order by 1,2
