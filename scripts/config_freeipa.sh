#!/bin/bash

# rationale: valida que el usuario que ejecute el script sea root
if [ $USER != 'root' ]; then
  echo 'El script debe ser ejecutado como ROOT'
  exit
fi

# rationale: dependencias freeipa sin DNS EXTERNO
yum install -y ipa-server-dns

if [ "$EXTERNAL_DNS" = "true" ]
then

  # rationale: configurar con DNS EXTERNO
  ipa-server-install << 'EOF'
no
freeipa.portal.glud.org
portal.glud.org
PORTAL.GLUD.ORG
mipasswordprueba
mipasswordprueba
adminpasswordprueba
adminpasswordprueba
yes
EOF

else
  # rationale: configurar sin DNS EXTERNO
  ipa-server-install << 'EOF'
yes
freeipa.portal.glud.org
portal.glud.org
PORTAL.GLUD.ORG
mipasswordprueba
mipasswordprueba
adminpasswordprueba
adminpasswordprueba
yes
yes
yes
yes
yes
EOF

fi


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