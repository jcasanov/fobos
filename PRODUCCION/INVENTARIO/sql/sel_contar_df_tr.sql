select r19_tipo_dev, r19_num_dev, count(*) hay
	from rept019
	where r19_compania   = 1
	  and r19_localidad in (1,2,3,4)
	  and r19_cod_tran   = 'TR'
	  and r19_tipo_dev   = 'DF'
	group by 1, 2
	having count(*)      > 1
	order by 3 desc;
