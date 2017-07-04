begin work;

insert into srit000 values (1, 'FOBOS', current);

insert into srit001 values (1, 1, 'BIENES', 'FOBOS', current);
insert into srit001 values (1, 2, 'SERVICIOS', 'FOBOS', current);

insert into srit002 values (1, 2006, '01', 'ENERO', 'FOBOS', current);
insert into srit002 values (1, 2006, '02', 'FEBRERO', 'FOBOS', current);
insert into srit002 values (1, 2006, '03', 'MARZO', 'FOBOS', current);
insert into srit002 values (1, 2006, '04', 'ABRIL', 'FOBOS', current);
insert into srit002 values (1, 2006, '05', 'MAYO', 'FOBOS', current);
insert into srit002 values (1, 2006, '06', 'JUNIO', 'FOBOS', current);
insert into srit002 values (1, 2006, '07', 'JULIO', 'FOBOS', current);
insert into srit002 values (1, 2006, '08', 'AGOSTO', 'FOBOS', current);
insert into srit002 values (1, 2006, '09', 'SEPTIEMBRE', 'FOBOS', current);
insert into srit002 values (1, 2006, '10', 'OCTUBRE', 'FOBOS', current);
insert into srit002 values (1, 2006, '11', 'NOVIEMBRE', 'FOBOS', current);
insert into srit002 values (1, 2006, '12', 'DICIEMBRE', 'FOBOS', current);

insert into srit003 values (1, '01', 'R', 'FOBOS', current);
insert into srit003 values (1, '02', 'C', 'FOBOS', current);
insert into srit003 values (1, '03', 'P', 'FOBOS', current);
insert into srit003 values (1, '04', 'R', 'FOBOS', current);
insert into srit003 values (1, '05', 'C', 'FOBOS', current);
insert into srit003 values (1, '06', 'P', 'FOBOS', current);
insert into srit003 values (1, '07', 'F', 'FOBOS', current);

insert into srit004 values (1, 1, 'FACTURA', null, 'FOBOS', current);
insert into srit004 values (1, 2, 'NOTA DE VENTA', null, 'FOBOS', current);
insert into srit004 values (1, 4, 'NOTA DE CREDITO', null, 'FOBOS', current);
insert into srit004 values (1, 5, 'NOTA DE DEBITO', null, 'FOBOS', current);
insert into srit004
	values (1, 18,
		'DOCUMENTOS AUTORIZADOS UTILIZADOS EN VENTAS EXCEPTO N/C N/D',
		null, 'FOBOS', current);

insert into srit005 values (1, 1, 'COMPRA', 'FOBOS', current);
insert into srit005 values (1, 2, 'VENTA', 'FOBOS', current);
insert into srit005 values (1, 3, 'IMPORTACION', 'FOBOS', current);

insert into srit008
	values (1, 0, 0,  mdy(01,01,1990), null, 'FOBOS', current);
insert into srit008
	values (1, 1, 10, mdy(01,01,1990), mdy(12,31,1999), 'FOBOS', current);
insert into srit008
	values (1, 2, 12, mdy(09,01,2001), null, 'FOBOS', current);
insert into srit008
	values (1, 3, 14, mdy(06,01,2001), mdy(08,31,2001), 'FOBOS', current);

insert into srit009 values (1, 0, 'S', '0', 'FOBOS', current);
insert into srit009 values (1, 2, 'S', '70', 'FOBOS', current);
insert into srit009 values (1, 3, 'S', '100', 'FOBOS', current);
insert into srit009 values (1, 4, 'S', '70/100', 'FOBOS', current);
insert into srit009 values (1, 0, 'B', '0', 'FOBOS', current);
insert into srit009 values (1, 1, 'B', '30', 'FOBOS', current);
insert into srit009 values (1, 3, 'B', '100', 'FOBOS', current);

insert into srit012
	values (1, 'R', 'REGISTRO UNICO CONTRIBUYENTE', 'FOBOS', current);
insert into srit012 values (1, 'C', 'CEDULA DE IDENTIDAD', 'FOBOS', current);
insert into srit012 values (1, 'P', 'PASAPORTE', 'FOBOS', current);
insert into srit012 values (1, 'F', 'CONSUMIDOR FINAL', 'FOBOS', current);
insert into srit012 values (1, 'O', 'NO APLICA', 'FOBOS', current);

insert into srit014
	values (1, '309', 1.00, 'POR SUMINISTROS Y MATERIALES', mdy(04,01,2003),
		null, 'N', 'FOBOS', current);

insert into srit018 values (1, '01', 'R', 1);
insert into srit018 values (1, '02', 'C', 1);
insert into srit018 values (1, '03', 'P', 1);
insert into srit018 values (1, '04', 'R', 2);
insert into srit018 values (1, '05', 'C', 2);
insert into srit018 values (1, '06', 'P', 2);
insert into srit018 values (1, '07', 'F', 2);

insert into srit019 values (1, '04', 'R', 18, 'FA');
insert into srit019 values (1, '05', 'C', 18, 'NV');
insert into srit019 values (1, '06', 'P', 18, 'NV');
insert into srit019 values (1, '07', 'F', 18, 'NV');
insert into srit019 values (1, '04', 'R', 4, 'NC');
insert into srit019 values (1, '05', 'C', 4, 'NC');
insert into srit019 values (1, '07', 'F', 4, 'NC');
insert into srit019 values (1, '04', 'R', 5, 'ND');
insert into srit019 values (1, '05', 'C', 5, 'ND');
insert into srit019 values (1, '07', 'F', 5, 'ND');

insert into srit020 values (1, 1, 2);

commit work;
