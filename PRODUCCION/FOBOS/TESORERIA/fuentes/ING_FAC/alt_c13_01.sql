begin work;

alter table "fobos".ordt013 add (c13_fecha_cadu date before c13_usuario);

commit work;
