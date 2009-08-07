begin work;

alter table talt028 add  t28_motivo_dev varchar(40,20) 
                          before t28_ot_ant;

update talt028 set t28_motivo_dev = 'N/A' where 1=1;

alter table talt028 modify  t28_motivo_dev varchar(40,20) not null; 

rollback work;
