create table "fobos".temp_01 
  (
    r10_compania integer ,
    r10_codigo char(15) ,
    r10_nombre varchar(35,20) ,
    r10_estado char(1) ,
    r10_tipo smallint ,
    r10_peso decimal(7,3) ,
    r10_uni_med char(7) ,
    r10_cantpaq smallint ,
    r10_cantveh smallint ,
    r10_partida varchar(15,8) ,
    r10_modelo varchar(10,5) ,
    r10_linea char(5) ,
    r10_rotacion char(2) ,
    r10_paga_impto char(1) ,
    r10_fob decimal(9,2) ,
    r10_monfob char(2) ,
    r10_precio_mb decimal(11,2) ,
    r10_precio_ma decimal(11,2) ,
    r10_costo_mb decimal(11,2) ,
    r10_costo_ma decimal(11,2) ,
    r10_costult_mb decimal(11,2) ,
    r10_costult_ma decimal(11,2) ,
    r10_cantped smallint ,
    r10_cantback smallint ,
    r10_comentarios varchar(120),
    r10_precio_ant decimal(11,2) ,
    r10_fec_camprec datetime year to second,
    r10_filtro char(10),
    r10_usuario varchar(10,5) ,
    r10_fecing datetime year to second ,
    r10_feceli datetime year to second,
    primary key (r10_compania,r10_codigo)  constraint "fobos".pk_temp_01
  );




