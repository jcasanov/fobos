create table veht042 
  (
    v42_compania integer not null ,
    v42_modelo char(15) not null ,
    v42_linea char(5) not null ,
    v42_bmp char(15),
    primary key (v42_compania,v42_modelo)  constraint "fobos".pk_veht042
  );

