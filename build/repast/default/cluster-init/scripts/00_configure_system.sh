#!/bin/bash -x 

configure_system()
{
     # set limits for HPC apps
     cat << EOF >> /etc/security/limits.conf
*               hard    memlock         unlimited
*               soft    memlock         unlimited
*               hard    nofile          65535
*               soft    nofile          65535
EOF

    # turn off GSS proxy
    sed -i 's/GSS_USE_PROXY="yes"/GSS_USE_PROXY="no"/g' /etc/sysconfig/nfs

    # Disable tty requirement for sudo
    sed -i 's/^Defaults[ ]*requiretty/# Defaults requiretty/g' /etc/sudoers

    # optimize
    systemctl disable cpupower
    systemctl disable firewalld

} #-- end of configure_system() --#

configure_system
