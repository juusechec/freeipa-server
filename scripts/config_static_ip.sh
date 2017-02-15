#!/bin/bash

# rationale: valida que el usuario que ejecute el script sea root
if [ $USER != 'root' ]; then
  echo 'El script debe ser ejecutado como ROOT'
  exit
fi

# rationale: poner IP estática
archivo='/etc/sysconfig/network-scripts/ifcfg-enp0s3'
if grep -i 'ONBOOT=yes' $archivo &> /dev/null
then
  echo "Ya existe la línea ONBOOT=yes el archivo $archivo"
else
  sed -i.bak '/^ONBOOT=/ s/no/yes/g' $archivo
  sed -i.bak '/^BOOTPROTO=/ s/dhcp/static/g' $archivo
  cat << 'EOF' >> $archivo
IPADDR=192.168.1.200
NETMASK=255.255.255.0
GATEWAY=192.168.1.1
NT_CONTROLLED=no
EOF
  systemctl restart network.service

  # rationale: configurar el DNS
  archivo='/etc/resolv.conf'
  cat << 'EOF' > $archivo
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF
fi

# rationale: se cambia NetworkManager por network
systemctl disable NetworkManager.service
systemctl enable network.service
systemctl stop NetworkManager.service
systemctl restart network.service
