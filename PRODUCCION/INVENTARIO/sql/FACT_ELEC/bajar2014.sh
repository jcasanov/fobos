#!/bin/bash 

# Aqu ponemos los datos de conexin 
USUARIO=1790008959001
#usuario 

CLAVE=1790008959001
#Password del usuario 

HOST=172.32.236.88
#cambiar por la dirección ip del servidor sftp 

PUERTO=22 
#el puerto de conexión con sftp este no cambia . 


cd XML;sshpass -p ${CLAVE} sftp ${USUARIO}@${HOST} << CMD 

#primero se cambia al directorio donde queremos que descarge los archivos 
#y luego se ejecuta la conexion al 
#final se coloca << CMD lo que indica que los comandos que se ejecutaran 
#hasta el cierre de la sentencia se 
#ejecutan en el servidor remoto y se cierra con CMD 

cd rechazados
#aqui se asume que dentro de la carpeta raiz hay otra que se llama IN a la cual ingresamos 


mget *.* 
#con este comando se descargan todos los archivos dentro de la carpeta IN del servidor sftp 

bye 
# este comando cierra la sesion 

CMD 
#este es el cierre de la conexion remota 
