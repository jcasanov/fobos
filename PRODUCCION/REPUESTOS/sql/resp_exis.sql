unload to "resp_exis_2003.unl" select * from resp_exis;
delete from resp_exis where 1 = 1;
insert into resp_exis select * from rept011;
