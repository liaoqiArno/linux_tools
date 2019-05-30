#!/bin/bash



#ROOT_PW=123456
#MANAGER_PW=654321

LDAP_ADD="ldapadd -Y EXTERNAL -H ldapi:/// -f"

DC1=2345
DC2=com

sed -i 's/enforcing/disabled/g' /etc/selinux/config
setenforce 0
systemctl stop firewalld
systemctl disable firewalld

echo "install ldap "
yum install -y openldap-servers openldap-clients
cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
chown ldap. /var/lib/ldap/DB_CONFIG
systemctl start slapd
systemctl enable slapd

read -p "please input root_pw:" var
ROOT_PW=`echo $var | slappasswd -stdin`
cat >> /etc/openldap/chrootpw.ldif << EOF

# specify the password generated above for "olcRootPW" section
dn: olcDatabase={0}config,cn=config
changetype: modify
add: olcRootPW
olcRootPW: $ROOT_PW
EOF

$LDAP_ADD /etc/openldap/chrootpw.ldif

###import module
$LDAP_ADD /etc/openldap/schema/cosine.ldif
$LDAP_ADD /etc/openldap/schema/nis.ldif
$LDAP_ADD /etc/openldap/schema/inetorgperson.ldif


read -p "please input manager_pw:" var1
MANAGER_PW=`echo $var1 | slappasswd -stdin`

cat >> /etc/openldap/chdomain.ldif << EOF
# replace to your own domain name for "dc=***,dc=***" section
# specify the password generated above for "olcRootPW" section
 dn: olcDatabase={1}monitor,cn=config
changetype: modify
replace: olcAccess
olcAccess: {0}to * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth"
  read by dn.base="cn=Manager,dc=$DC1,dc=$DC2" read by * none

dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: dc=$DC1,dc=$DC2

dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcRootDN
olcRootDN: cn=Manager,dc=$DC1,dc=$DC2

dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcRootPW
olcRootPW: $MANAGER_PW

dn: olcDatabase={2}hdb,cn=config
changetype: modify
add: olcAccess
olcAccess: {0}to attrs=userPassword,shadowLastChange by
  dn="cn=Manager,dc=$DC1,dc=$DC2" write by anonymous auth by self write by * none
olcAccess: {1}to dn.base="" by * read
olcAccess: {2}to * by dn="cn=Manager,dc=$DC1,dc=$DC2" write by * read
EOF


$LDAP_ADD /etc/openldap/chdomain.ldif

cat >> /etc/openldap/basedomain.ldif <<EOF
# replace to your own domain name for "dc=***,dc=***" section
 dn: dc=$DC1,dc=$DC2
objectClass: top
objectClass: dcObject
objectclass: organization
o: Server ${DC1}.${DC2}
dc: $DC1

dn: cn=Manager,dc=$DC1,dc=$DC2
objectClass: organizationalRole
cn: Manager
description: Directory Manager

dn: ou=People,dc=$DC1,dc=$DC2
objectClass: organizationalUnit
ou: People

dn: ou=Group,dc=$DC1,dc=$DC2
objectClass: organizationalUnit
ou: Group
EOF

ldapadd -x -D cn=Manager,dc=$DC1,dc=$DC2 -W -f basedomain.ldif