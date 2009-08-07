--alter table te_new_precios drop te_peso;
--delete from te_new_precios where 1 = 1;
--load from "komatsu.csv" insert into te_new_precios

alter table te_new_precios add (te_peso decimal(9,2));
