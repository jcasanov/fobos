select unique r19_usuario, count(*) total_fact
	from rept019
	where r19_compania   = 1
	  and r19_localidad in (3, 5)
	  and r19_cod_tran   = 'FA'
	group by 1
	order by 1;
begin work;
update rept019 set r19_usuario = 'E1SILRIV'
	where r19_compania   = 1
	  and r19_localidad in (3, 5)
	  and r19_cod_tran   = 'FA'
	  and r19_usuario    = 'F1VINVIN';
commit work;
select unique r19_usuario, count(*) total_fact
	from rept019
	where r19_compania   = 1
	  and r19_localidad in (3, 5)
	  and r19_cod_tran   = 'FA'
	group by 1
	order by 1;
