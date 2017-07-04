select * from cajt010 into temp t1;
select j14_cont_cred t, count(*) total
        from cajt014
        where extend(j14_fecha_emi, year to month) = '2008-05'
        group by 1;
{--
select j14_cod_tran ct, j14_num_tran num, count(*) total
        from cajt014
        group by 1, 2
	having count(*) > 1
	order by 2;
--}
select j14_cont_cred t, j10_estado e, extend(j10_fecha_pro, year to month) fec,
        count(*) total
        from cajt014, outer t1
        where extend(j14_fecha_emi, year to month) = '2008-05'
          and j10_compania     = j14_compania
          and j10_localidad    = j14_localidad
	  and j10_estado       = 'P'
	  and j10_tipo_fuente  = j14_tipo_fue
          and j10_tipo_destino = j14_cod_tran
          and j10_num_destino  = j14_num_tran
        group by 1, 2, 3
        order by 3;
select j14_cont_cred t, j10_estado e, extend(j10_fecha_pro, year to day) fec,
        j10_tipo_fuente tf, j10_num_fuente nf,
        j14_tipo_fuente tf4, j14_num_fuente nf4,
	extend(j14_fecha_emi, year to day) fec_ret, j14_localidad loc
        from cajt014, outer t1
        where extend(j14_fecha_emi, year to month) = '2008-05'
          and j10_compania     = j14_compania
          and j10_localidad    = j14_localidad
	  and j10_estado       = 'P'
	  and j10_tipo_fuente  = j14_tipo_fue
          and j10_tipo_destino = j14_cod_tran
          and j10_num_destino  = j14_num_tran
        order by 1 desc, 8, 3;
drop table t1;
