#!/bin/bash
echo 'Ejecutando: config_freeipa.sh'

# rationale: valida que el usuario que ejecute el script sea root
if [ $USER != 'root' ]; then
  echo 'El script debe ser ejecutado como ROOT'
  exit
fi

if [ "$EXTERNAL_DNS" = "true" ]
then

  # rationale: configurar con DNS EXTERNO
  ipa-server-install << 'EOF'




mipasswordprueba
mipasswordprueba
adminpasswordprueba
adminpasswordprueba
yes
EOF

else

  # rationale: dependencias freeipa sin DNS EXTERNO
  yum install -y ipa-server-dns

  # rationale: configurar sin DNS EXTERNO
  ipa-server-install << 'EOF'
yes



mipasswordprueba
mipasswordprueba
adminpasswordprueba
adminpasswordprueba
192.168.100.200







yes
EOF

fi

# rationale: mostrar al usuario lo que se puede hacer
cat << 'EOF'
less /var/log/ipaserver-install.log
kinit admin
klist
ipa config-mod --defaultshell=/bin/bash
ipa user-add juusechec --first=Jorge --last=Useche --password
# ingresar por la URL https://freeipa.portal.glud.org/
#xdg-open https://freeipa.portal.glud.org
ldapwhoami -vvv -h freeipa.portal.incige.org -p 389 -D "uid=juusechec,cn=users,cn=accounts,dc=portal,dc=glud,dc=org" -x -w password
ldapsearch -x uid=admin # en el freeipa http://www.freeipa.org/page/HowTo/LDAP
ldapsearch -x -h freeipa.portal.incige.org  -b dc=portal,dc=glud,dc=org uid=admin # en otro lado
EOF
