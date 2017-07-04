alter table srit015 drop s15_descripcion_fid;
alter table srit015
	add (s15_descrip_fid varchar(60,40) not null before s15_codigo_ret);
