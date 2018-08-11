begin work;

alter table rept086 add(r86_precio_nue decimal(11,2) before r86_fec_camprec);

update rept086 set r86_precio_nue = (select r10_precio_mb from rept010
					where r10_compania = 1
					  and r10_codigo   = r86_item)
	where r86_compania = 1
	  and r86_codigo   = 1;

alter table rept086 modify(r86_precio_nue decimal(11,2) not null);

commit work;

select * from rept086;
