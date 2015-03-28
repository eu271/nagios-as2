#!/bin/sh
#
#The MIT License (MIT)
#
#Copyright (c) 2015 Eugenio Ochoa Lopez
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.

#Las url estan aqui, para una posible actualizacion a versiones siguientes, notese
#que el proceso de instalacion podria cambiar y cambios adicionales tendrian que 
#hacerse.
URL_NAGIOS_CORE="http://prdownloads.sourceforge.net/sourceforge/nagios/nagios-4.0.4.tar.gz"
URL_NAGIOS_PLUGINS="http://nagios-plugins.org/download/nagios-plugins-2.0.tar.gz"

FILE_NAGIOS_CORE=$(echo ${URL_NAGIOS_CORE}| cut -d/ -f6)
FILE_NAGIOS_PLUGINS=$(echo ${URL_NAGIOS_PLUGINS}| cut -d/ -f5)

DIR_NAGIOS_CORE=$(echo ${FILE_NAGIOS_CORE}| cut -d. -f1,2,3)
DIR_NAGIOS_PLUGINS=$(echo ${FILE_NAGIOS_PLUGINS}| cut -d. -f1,2)

#Instala todas las librerias y extras para el funcionamiento de nagios como servidor
#Ademas tambien añade todo lo necesario para la configuracion y funcionamiento CGI
apt-get install -y wget build-essential apache2 php5-gd libgd2-xpm libgd2-xpm-dev libapache2-modphp5

#Añade los usuarios pertinentes para el funcionamiento de nagios ademas de los grupos
#para compartir permisos.
echo "Añadiendo usuario para nagios:" 
useradd nagios
groupadd nagcmd
usermod -a -G nagcmd nagios
usermod -a -G nagcmd www-data

#Descarga de los tarball
cd /tmp
wget $URL_NAGIOS_CORE
wget $URL_NAGIOS_PLUGINS

#Descomprecion de los tarball
tar zxvf $FILE_NAGIOS_CORE
tar zxvf $FILE_NAGIOS_PLUGINS

#Instalacion de nagios
cd $DIR_NAGIOS_CORE

./configure --with-nagios-group=nagios --with-command-group=nagcmd -–with-mail=/usr/bin/sendmail

make all
make install
make install-init
make install-config
make install-commandmode
make install-webconf 

cp -R contrib/eventhandlers/ /usr/local/nagios/libexec/
chown -R nagios:nagios /usr/local/nagios/libexec/eventhandlers

echo "Añadiendo usuario para la web:"
htpasswd –c /usr/local/nagios/etc/htpasswd.users nagiosadmin


#Instalacion de los plugins en nagios
echo "Instalacion de los plugins nagios:"
cd /tmp/$DIR_NAGIOS_PLUGINS
./configure --with-nagios-user=nagios --with-nagios-group=nagios
make
make install 

echo "Añadiendo nagios al inicio del sistema:"
ln -s /etc/init.d/nagios /etc/rcS.d/S99nagios


/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg
/etc/init.d/apache2 reload && /etc/init.d/nagios start

