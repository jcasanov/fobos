begin work;

select r19_cod_tran, ' ' externo, r19_num_tran interno,
       DATE(r19_fecing) fecha,
       r19_nomcli cliente, r19_cedruc RUC, ' ' autorizacion,
       r19_tot_bruto valor_bruto, r19_tot_dscto descto,
       (r19_tot_bruto - r19_tot_dscto) valor_sin_iva, r19_porc_impto, 
       round((1/3),2) iva, r19_tot_neto total
  from rept019
 where r19_compania  = 1
   and r19_localidad = 1
   and r19_cod_tran  IN ('FA', 'DF', 'AF')
   and DATE(r19_fecing) between mdy(02, 01, 2004) and mdy(02, 29, 2004)
into temp tt_jcm;

update tt_jcm set iva = valor_sin_iva * r19_porc_impto / 100 where 1=1;

unload to 'listado.txt' 
select externo, interno, fecha, cliente, RUC, autorizacion, valor_bruto,
       descto, valor_sin_iva, iva, total
  from tt_jcm
 where r19_cod_tran = 'FA'
 order by fecha asc;

rollback work;
