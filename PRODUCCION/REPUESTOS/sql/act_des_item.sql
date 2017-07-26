set isolation to dirty read;

--rollback work;

begin work;

update rept010
	set r10_nombre = replace(r10_nombre, '§', 'ø')
	where r10_compania in(1, 2)
	  and r10_nombre   matches '*§*';

commit work;
