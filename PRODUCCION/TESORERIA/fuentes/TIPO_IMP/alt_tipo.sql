begin work;

-- INSERTANDO NUEVA COLUNMA EN TABLA: cxpt005

alter table "fobos".cxpt005 add (p05_codigo_sri char(6));

create index "fobos".i04_fk_cxpt005 on "fobos".cxpt005
	(p05_compania, p05_tipo_ret, p05_porcentaje, p05_codigo_sri) in idxdbs;

alter table "fobos".cxpt005
	add constraint
		(foreign key (p05_compania, p05_tipo_ret, p05_porcentaje,
				p05_codigo_sri)
			references "fobos".ordt003
			constraint fk_04_cxpt005);

--
--

-- INSERTANDO NUEVA COLUNMA EN TABLA: cxpt026

alter table "fobos".cxpt026
	add (p26_codigo_sri char(6) before p26_valor_base);

create index "fobos".i03_fk_cxpt026 on "fobos".cxpt026
	(p26_compania, p26_tipo_ret, p26_porcentaje, p26_codigo_sri) in idxdbs;

alter table "fobos".cxpt026
	add constraint
		(foreign key (p26_compania, p26_tipo_ret, p26_porcentaje,
				p26_codigo_sri)
			references "fobos".ordt003
			constraint fk_03_cxpt026);

--
--

-- INSERTANDO NUEVA COLUNMA EN TABLA: cxpt028

alter table "fobos".cxpt028
	add (p28_codigo_sri char(6) before p28_valor_base);

create index "fobos".i03_fk_cxpt028 on "fobos".cxpt028
	(p28_compania, p28_tipo_ret, p28_porcentaje, p28_codigo_sri) in idxdbs;

alter table "fobos".cxpt028
	add constraint
		(foreign key (p28_compania, p28_tipo_ret, p28_porcentaje,
				p28_codigo_sri)
			references "fobos".ordt003
			constraint fk_03_cxpt028);

--
--

commit work;
