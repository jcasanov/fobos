begin;
alter table ctbt040 add b40_dif_costo char(12) ;
update ctbt040 set b40_dif_costo = b40_inventario where 1 = 1;
alter table ctbt040 modify b40_dif_costo char(12) not null;
alter table rept000 drop r00_cta_recepcion;
commit;
