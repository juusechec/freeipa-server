# Despliegue servidor de FreeIPA

En este repositorio se ponen los pasos de despliegue de un servidor proveedor de identidad.

# Instrucciones de USO
No fue posible para mi poner la configuración y la instalación en un solo paso,
ya que la instalación necesita que se configure y ***reinicie*** el servidor.
Hay que hacer vagrant provision 2 veces, una de esas después del reboot.

1) Inicie la máquina:
```bash
vagrant up
```

2) Provisione la máquina:
```bash
vagrant provision
vagrant provision
```

3) Si no agregó un DNS configure su ***/etc/hosts*** o
***C:\Windows\System32\drivers\etc*** y agregue la entrada:
```bash
192.168.100.200		freeipa.portal.glud.org
```

4) Acceda a la URL https://freeipa.portal.glud.org/ipa/ui/ desde un navegador web.
```
Usuario: admin
Clave: adminpasswordprueba
```

# Redimensionar disco vmdk virtualbox
## Convertir vmdk a vdi
http://stackoverflow.com/questions/11659005/how-to-resize-a-virtualbox-vmdk-file
```bash
"c:\program files\oracle\virtualbox\vboxmanage" clonehd "C:\Users\AI-servidor\VirtualBox VMs\Drupal\Drupal-disk1.vmdk" "C:\Users\AI-servidor\VirtualBox VMs\Drupal\Drupal-disk1.vdi" --format VDI
"c:\program files\oracle\virtualbox\vboxmanage" modifyhd "C:\Users\AI-servidor\VirtualBox VMs\Drupal\Drupal-disk1.vdi" --resize 30720
```
## Aumentar el espacio de la raiz en un LVM en caliente
https://www.rootusers.com/how-to-increase-the-size-of-a-linux-lvm-by-expanding-the-virtual-machine-disk/
