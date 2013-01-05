nvidia-optimus-install
======================

Descripcion
======================
Script para la instalacion de la GPU Nvidia de las notebooks con Optimus en Fedora  Linux

Guia de Instalacion
======================
Desde una terminal descargar el source code haciendo

$ git clone https://github.com/nuxlic/nvidia-optimus-install

Acceder al directorio del script

$ cd nvidia-optimus-install

Ejecutar el script

$ sudo sh Install.sh

Nota: si no posee sudo el comado es:

$ su

$ sh Install.sh

Al momento de Instalarse el driver tener en cuenta:

1. Preguntara si queremos instalarlo con dmks. Ponemos que si

2. Preguntara si queremos instalar las librerias de 32 bits. Ponemos que si

Y eso es todo. El resto de la instalacion se hace de manera automatica

Esto fue como instalar Nvidia Optimus en Fedora Linux, espero que les haya gustado
chau!
