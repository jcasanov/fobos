
select * from rept020 where r20_compania =1 and r20_localidad = 4 and
	 r20_cod_tran = 'FA' and
	 r20_num_tran = 1817;
{
select * from cajt010 where j10_tipo_destino = 'FA' and
	j10_num_destino = '1817';

select * from rept023 where r23_numprof = 3048;
select * from rept021 where r21_numprof = 3048 ;
select * from rept025 where r25_cod_tran = 'FA' and r25_num_tran = 1617

select * from cxct020 where z20_cod_tran = 'FA' and
	z20_num_tran = 551

}

select r23_numprev, r23_fecing from rept023
	where date(r23_fecing) = mdy(04,03,2003)
	order by 2
