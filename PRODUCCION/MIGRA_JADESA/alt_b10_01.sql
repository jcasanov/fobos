begin work;

	alter table ctbt010
		modify b10_descripcion varchar(100,40) not null;

commit work;
