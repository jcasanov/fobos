set isolation to dirty read;

begin work;

update rept010
	set r10_nombre = replace(r10_nombre, '°', ' GRAD ')
	where r10_compania in(1, 2)
	  and r10_nombre   matches '*°*';

update rept010
	set r10_cod_pedido = replace(r10_cod_pedido, '°', ' GRAD ')
	where r10_compania   in(1, 2)
	  and r10_cod_pedido matches '*°*';

update rept010
	set r10_cod_comerc = replace(r10_cod_comerc, '°', ' GRAD ')
	where r10_compania   in(1, 2)
	  and r10_cod_comerc matches '*°*';

--rollback work;
commit work;
