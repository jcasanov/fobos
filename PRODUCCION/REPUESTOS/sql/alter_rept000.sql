begin;
alter table rept000 add r00_cta_recepcion char(12) before r00_contr_prof;
update rept000 set r00_cta_recepcion = (select c00_cta_recepcion
										  from ordt000
										 where c00_compania  = r00_compania)
 where r00_compania = 1;
alter table rept000 modify r00_cta_recepcion char(12) not null;
create index i04_fk_rept000 on rept000(r00_compania, r00_cta_recepcion);
alter table rept000 add constraint (
	foreign key (r00_compania, r00_cta_recepcion)
	references ctbt010 (b10_compania, b10_cuenta));
alter table ordt000 drop c00_cta_recepcion;
commit;
