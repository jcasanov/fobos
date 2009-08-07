alter table rept091 add r91_tipo_tran char(1) check (r91_tipo_tran in ('I', 'E', 'C', 'T')) before r91_usuario;
alter table rept091 add r91_calc_costo char(1) check (r91_calc_costo in ('S', 'N')) before r91_usuario;
