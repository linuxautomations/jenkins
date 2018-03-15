#!/bin/bash

## Source Common Functions
curl -s "https://raw.githubusercontent.com/linuxautomations/scripts/master/common-functions.sh" >/tmp/common-functions.sh
#source /root/scripts/common-functions.sh
source /tmp/common-functions.sh

## Checking Root User or not.
CheckRoot

## Checking SELINUX Enabled or not.
CheckSELinux

## Checking Firewall on the Server.
CheckFirewall

Check_Jenkins_Start() {
    i=180 # 100 Seconds
    while [ $i -gt 0 ]; do 
        netstat -lntp | grep 8080 &>/dev/null 
        if [ $? -eq 0 ]; then 
            return 0
        else
            i=$(($i-10))
            sleep 10
            continue 
        fi 
    done
    return 1
}

### Install Jenkins
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo &>/dev/null
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key &>/dev/null
yum install jenkins java -y &>/dev/null
Stat $? "Installing Jenkins"
systemctl enable jenkins &>/dev/null
systemctl start jenkins
Check_Jenkins_Start
Stat $? "Starting Jenkins"
systemctl stop jenkins

sed -i -e '/isSetupComplete/ s/false/true/' -e '/name/ s/NEW/RUNNING/' /var/lib/jenkins/config.xml
mkdir -p /var/lib/jenkins/users/admin 
curl -s https://raw.githubusercontent.com/linuxautomations/jenkins/master/admin.xml >/var/lib/jenkins/users/admin/config.xml
chown jenkins:jenkins /var/lib/jenkins/users -R 
systemctl start jenkins
Stat $? "Configuring Jenkins"

### Final Status
PU_IP=$(curl ifconfig.co)

head_bu "Access the Jenkins using following URL and Credentials"
info "http://$PU_IP:8080"
info "Username : admin"
info "Password : admin"

