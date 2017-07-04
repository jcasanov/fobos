set isolation to dirty read;

begin work;

update rept072
	set r72_desc_clase = replace(r72_desc_clase, '°', ' GRAD ')
	where r72_compania   in (1, 2)
	  and r72_desc_clase matches '*°*';

--rollback work;
commit work;
