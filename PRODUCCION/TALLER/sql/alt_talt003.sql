begin work;

alter table talt003 add
	t03_hora_ini 		datetime hour to minute
	before t03_usuario;

alter table talt003 add
	t03_hora_fin 		datetime hour to minute
	before t03_usuario;

alter table talt003 add
	t03_cost_hvn 		decimal(5,2)           
	before t03_usuario;

alter table talt003 add
	t03_cost_hve 		decimal(5,2)           
	before t03_usuario;

alter table talt003 add
	t03_cost_htn 		decimal(5,2)           
	before t03_usuario;

alter table talt003 add
	t03_cost_hte 		decimal(5,2)           
	before t03_usuario;

alter table talt003 add
	t03_fact_hvn 		decimal(5,2)           
	before t03_usuario;

alter table talt003 add
	t03_fact_hve 		decimal(5,2)           
	before t03_usuario;

alter table talt003 add
	t03_fact_htn 		decimal(5,2)           
	before t03_usuario;

alter table talt003 add
	t03_fact_hte 		decimal(5,2)           
	before t03_usuario;

-----------
update talt003 set t03_cost_hvn = 0, t03_cost_hve = 0, t03_cost_htn = 0,
		   t03_cost_hte = 0, t03_fact_hvn = 0, t03_fact_hve = 0,
		   t03_fact_htn = 0, t03_fact_hte = 0;

----------------

alter table talt003 modify t03_cost_hvn decimal(5,2) not null;
alter table talt003 modify t03_cost_hve decimal(5,2) not null;
alter table talt003 modify t03_cost_htn decimal(5,2) not null;
alter table talt003 modify t03_cost_hte decimal(5,2) not null;
alter table talt003 modify t03_fact_hvn decimal(5,2) not null;
alter table talt003 modify t03_fact_hve decimal(5,2) not null;
alter table talt003 modify t03_fact_htn decimal(5,2) not null;
alter table talt003 modify t03_fact_hte decimal(5,2) not null;

commit work;
