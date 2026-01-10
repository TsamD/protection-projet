#! /usr/bin/bash -x
set -euo pipefail

# inspiré de
# https://tldp.org/HOWTO/LVM-HOWTO/snapshots_backup.html
# https://connect.ed-diamond.com/Linux-Pratique/lphs-049/sauvegardez-vos-donnees-centralisez-vos-logs-et-supervisez-votre-securite
# vérifier connectivité et présence du disque monté
# sauvegarde proprement dite
rsync -avx --delete --rsync-path="/usr/bin/rsync" -e "ssh -i /home/vagrant/.ssh/id_rsa" vagrant@ldap-compta.interface3.be:/finance/ sauvegarde
# vérification contenu sauvegarde
ls -l ./sauvegarde
