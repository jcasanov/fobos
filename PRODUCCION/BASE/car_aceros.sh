. /acero/envfobos.sh
export ruta=$PWD
export DIR="$HOME/RESPALDO/DIARIO/"
cd $DIR
time rcp srvgye01:/acero/fobos/RESPALDO/DIARIO/acero_gm.tar.gz . ; date
cd $HOME/PRODUCCION/TRAB_EXTRA/FOBOS/BASE/
time sh cargar_base_prueba acero_gm aceros; date
