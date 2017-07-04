
DATABASE aceros

GLOBALS

DEFINE vg_producto	VARCHAR(10)
DEFINE vg_proceso	LIKE gent054.g54_proceso
DEFINE vg_base		LIKE gent051.g51_basedatos
DEFINE vg_modulo	LIKE gent050.g50_modulo
DEFINE vg_codcia	LIKE gent001.g01_compania
DEFINE vg_codloc	LIKE gent002.g02_localidad
DEFINE vg_usuario	LIKE gent005.g05_usuario
DEFINE vg_separador	LIKE fobos.fb_separador
DEFINE vg_dir_fobos	LIKE fobos.fb_dir_fobos
DEFINE vg_gui		SMALLINT

DEFINE rg_gen		RECORD LIKE gent000.* 
DEFINE rg_cia		RECORD LIKE gent001.* 
DEFINE rg_loc		RECORD LIKE gent002.* 
DEFINE rg_mod		RECORD LIKE gent050.* 
DEFINE rg_pro		RECORD LIKE gent054.* 

DEFINE ag_one 	ARRAY[9] OF CHAR (6)
DEFINE ag_two 	ARRAY[9] OF CHAR (10)
DEFINE ag_three ARRAY[9] OF CHAR (9)
DEFINE ag_four 	ARRAY[9] OF CHAR (13)
DEFINE ag_five 	ARRAY[9] OF CHAR (13)

END GLOBALS
