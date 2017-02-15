#!/bin/bash
echo 'Ejecutando: install_freeipa.sh'

# rationale: valida que el usuario que ejecute el script sea root
if [ $USER != 'root' ]; then
  echo 'El script debe ser ejecutado como ROOT'
  exit
fi

# rationale: validar que es CentOS
if ! cat /etc/os-release | grep -i 'centos' &> /dev/null
then
  echo 'Su distribución no es CentOS.'
  exit 1
fi

# rationale: anunciar que si no tiene Centos versión 7 el instalador puede fallar
if ! cat /etc/os-release | grep -i 'VERSION="7"' &> /dev/null
then
  echo 'Su distribución no es CentOS versión 7, tal vez no funcione.'
fi

# rationale: selinux permissive
archivo=/etc/selinux/config
if grep -ie '^SELINUX=permissive' $archivo &> /dev/null
then
  echo "El archivo $archivo ya está modificado. Nada que hacer."
else
  sed -i.bak '/^SELINUX=/ s/enforcing/permissive/g' $archivo
  setenforce 0
  sestatus
fi

if [ "$EXTERNAL_DNS" = "true" ]
then
  # rationale: agrega la línea al archivo para configurar el DNS
  dns='nameserver 192.168.1.20'
  archivo='/etc/resolv.conf'
  if grep -i "$dns" $archivo &> /dev/null
  then
    echo "El archivo $archivo ya está modificado. Nada que hacer."
  else
    cp $archivo $archivo.bak
    echo $dns >> $archivo
    grep -i "$dns" $archivo
  fi
else
  # rationale: agrega la línea al archivo a host para emular DNS
  domain='192.168.100.200 freeipa.portal.glud.org freeipa'
  archivo='/etc/hosts'
  if grep -i "$domain" $archivo &> /dev/null
  then
    echo "El archivo $archivo ya está modificado. Nada que hacer."
  else
    cp $archivo $archivo.bak
    echo $domain >> $archivo
    grep -i "$domain" $archivo
  fi
fi

# rationale: configurar hora del sistema
archivo='/etc/localtime.bak'
if [ -f $archivo ]
then
  echo "El archivo $archivo ya existe. Nada que hacer."
else
  systemctl stop chronyd.service
  systemctl disable chronyd.service
  cp /etc/localtime /etc/localtime.bak
  cp /usr/share/zoneinfo/America/Bogota /etc/localtime
  yum install -y ntp
  systemctl enable ntpd.service
  timedatectl set-ntp 1
  systemctl restart ntpd.service
  # para verificar
  sleep 1 # tiempo para que inicie el servicio
  ntpq -p
  date
fi

# rationale: instalar  herramientas de administración
yum update -y
yum install -y epel-release
yum install -y vim nano wget curl system-storage-manager mlocate --skip-broken
yum install -y --skip-broken net-tools iproute mtr sed curl htop iptraf lsof \
  deltarpm telnet nc yum-plugin-security yum-plugin-replace yum-utils  \
  bind-utils yum-fastestmirror rsync tree rpmconf iotop lsscsi \
  iscsi-initiator-utils sg3_utils device-mapper-multipath
yum install -y --skip-broken arp-scan mcstrans setools-console setools \
  setroubleshoot-server libselinux-utils selinux-policy-targeted \
  policycoreutils policycoreutils-python selinux-policy
yum install -y --skip-broken kpartx parted util-linux-ng \
  system-config-network-tui traceroute pciutils bash-completion ethtool \
  lsof system-config-firewall-tui whowatch

# rationale: instalar dependencias de freeipa
yum install -y vim rsync oddjob-mkhomedir bind-dyndb-ldap bind bind-utils \
  bind-chroot memcached java-atk-wrapper haveged

# rationale: habilitar haveged, aumenta la entropía para mejorar el rendimiento
# WARNING: Your system is running out of entropy, you may experience long delays
systemctl start haveged.service
systemctl enable haveged.service
systemctl status haveged.service -l

# rationale: instalar freeipa
yum install -y freeipa-server
firewall-cmd --set-default-zone=public

# rationale: se crean archivos con las reglas de freeipa para firewalld
archivo='/etc/firewalld/services/freeipa-ldaps.xml'
if [ -f $archivo ]
then
  echo "El archivo $archivo ya existe. Nada que hacer."
else
  cat << 'EOF' > $archivo
<?xml version="1.0" encoding="utf-8"?>
<service>
  <short>FreeIPA with LDAPS</short>
  <description>FreeIPA is an LDAP and Kerberos domain controller for Linux systems. Enable this option if you plan to provide a FreeIPA Domain Controller using the LDAPS protocol. You can also enable the 'freeipa-ldap' service if you want to  provide the LDAP protocol. Enable the 'dns' service if this FreeIPA server provides DNS services and 'freeipa-replication' service if this FreeIPA server is part of a multi-master replication setup.</description>
  <port protocol="tcp" port="80"/>
  <port protocol="tcp" port="443"/>
  <port protocol="tcp" port="88"/>
  <port protocol="udp" port="88"/>
  <port protocol="tcp" port="464"/>
  <port protocol="udp" port="464"/>
  <port protocol="udp" port="123"/>
  <port protocol="tcp" port="636"/>
</service>
EOF
fi

archivo='/etc/firewalld/services/freeipa-ldap.xml'
if [ -f $archivo ]
then
  echo "El archivo $archivo ya existe. Nada que hacer."
else
  cat << 'EOF' > $archivo
<?xml version="1.0" encoding="utf-8"?>
<service>
  <short>FreeIPA with LDAP</short>
  <description>FreeIPA is an LDAP and Kerberos domain controller for Linux systems. Enable this option if you plan to provide a FreeIPA Domain Controller using the LDAP protocol. You can also enable the 'freeipa-ldaps' service if you want to  provide the LDAPS protocol. Enable the 'dns' service if this FreeIPA server provides DNS services and 'freeipa-replication' service if this FreeIPA server is part of a multi-master replication setup.</description>
  <port protocol="tcp" port="80"/>
  <port protocol="tcp" port="443"/>
  <port protocol="tcp" port="88"/>
  <port protocol="udp" port="88"/>
  <port protocol="tcp" port="464"/>
  <port protocol="udp" port="464"/>
  <port protocol="udp" port="123"/>
  <port protocol="tcp" port="389"/>
</service>
EOF
fi

archivo='/etc/firewalld/services/freeipa-replication.xml'
if [ -f $archivo ]
then
  echo "El archivo $archivo ya existe. Nada que hacer."
else
  cat << 'EOF' > $archivo
<?xml version="1.0" encoding="utf-8"?>
<service>
  <short>FreeIPA replication</short>
  <description>FreeIPA is an LDAP and Kerberos domain controller for Linux systems. Enable this option if you want to enable LDAP replication between FreeIPA servers.</description>
  <port protocol="tcp" port="7389"/>
</service>
EOF
fi

# rationale: cargar las políticas nuevas
firewall-cmd --reload
firewall-cmd --zone=public --permanent --add-service=freeipa-ldaps
firewall-cmd --zone=public --permanent --add-service=freeipa-ldap
firewall-cmd --zone=public --permanent --add-service=freeipa-replication
firewall-cmd --reload
firewall-cmd --zone=public --list-all

# rationale: se configura directorios para los usuarios
authconfig --enablemkhomedir --update

# rationale: mostrar siguientes pasos
echo 'Después de reiniciar ejecute el archivo config_freeipa.sh'

# rationale: reiniciar para recargar los cambios
# todo: revisar si en serio se necesita para ejecutar config_freeipa.sh
if [ -f /usr/sbin/ipa-server-install ]
then
  echo 'No necesita reiniciar. FREEIPA esta instalado.'
else
  systemctl reboot
fi
