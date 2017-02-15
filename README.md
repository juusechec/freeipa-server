# Despliegue servidor de FreeIPA

En este repositorio se ponen los pasos de despliegue de un servidor proveedor de identidad.

# Redimensionar disco vmdk virtualbox
## Convertir vmdk a vdi
http://stackoverflow.com/questions/11659005/how-to-resize-a-virtualbox-vmdk-file
```bash
"c:\program files\oracle\virtualbox\vboxmanage" clonehd "C:\Users\AI-servidor\VirtualBox VMs\Drupal\Drupal-disk1.vmdk" "C:\Users\AI-servidor\VirtualBox VMs\Drupal\Drupal-disk1.vdi" --format VDI
"c:\program files\oracle\virtualbox\vboxmanage" modifyhd "C:\Users\AI-servidor\VirtualBox VMs\Drupal\Drupal-disk1.vdi" --resize 30720
```
## Aumentar el espacio de la raiz en un LVM en caliente
https://www.rootusers.com/how-to-increase-the-size-of-a-linux-lvm-by-expanding-the-virtual-machine-disk/
