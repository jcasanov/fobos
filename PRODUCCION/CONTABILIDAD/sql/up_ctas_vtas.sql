select count(*) tot_cta
	from ctbt010
	where b10_compania = 1
	  and b10_cuenta   matches '4104*';
select b10_cuenta, b10_fecing
	from ctbt010
	where b10_compania = 1
	  and b10_cuenta   matches '4104*'
	order by 1;
begin work;
delete from ctbt010
	where b10_compania = 1
	  and b10_cuenta   = '41040000';
update ctbt010
	set b10_cuenta = replace(b10_cuenta, '410401', '410203')
	where b10_compania = 1
	  and b10_cuenta   matches '410401*';
select b10_cuenta, b10_fecing
	from ctbt010
	where b10_compania = 1
	  and b10_cuenta   matches '410203*';
--rollback work;
commit work;
