time sh crea_tabla $1

time sh pasa_prog

cd $HOME/PRODUCCION/

time sh comp_alt_all $1 | tee comp_alt_all.log; date

cd $HOME
