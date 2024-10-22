#!/bin/bash

######################################################################
# Script Name: setup_environment.sh
# Description: Automated setup script for environment configuration
# Author: OpenAI
# Created: 2023-06-16
######################################################################

# Check if the script is running with root privileges
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run with root privileges. Exiting..."
  exit 1
fi

# Check if the current yum repository is mirrors.aliyun.com/repo/Centos-7.repo
yum_repo=$(grep -o "mirrors.aliyun.com/repo/Centos-7.repo" /etc/yum.repos.d/CentOS-Base.repo)
if [ -z "$yum_repo" ]; then
  echo "Changing the default yum repository..."
  curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
  yum install -y yum-utils device-mapper-persistent-data lvm2
  yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
  cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
  sed -i -e '/mirrors.cloud.aliyuncs.com/d' -e '/mirrors.aliyuncs.com/d' /etc/yum.repos.d/CentOS-Base.repo
fi

# Check if git, wget, vim tools are installed
echo "Checking required tools..."
if ! command -v git &> /dev/null || ! command -v wget &> /dev/null || ! command -v vim &> /dev/null; then
  echo "Installing required tools..."
  yum install wget jq psmisc lrzsz vim net-tools telnet yum-utils device-mapper-persistent-data lvm2 git expect -y
fi

# Disable firewalld, dnsmasq, and NetworkManager
echo "Disabling firewalld, dnsmasq, and NetworkManager..."
systemctl disable --now firewalld
systemctl disable --now dnsmasq
systemctl disable --now NetworkManager

# Disable SELinux
echo "Disabling SELinux..."
setenforce 0
sed -i 's#SELINUX=enforcing#SELINUX=disabled#g' /etc/sysconfig/selinux
sed -i 's#SELINUX=enforcing#SELINUX=disabled#g' /etc/selinux/config

# Disable swap and modify /etc/fstab
echo "Disabling swap and modifying /etc/fstab..."
swapoff -a && sysctl -w vm.swappiness=0
sed -ri '/^[^#]*swap/s@^@#@' /etc/fstab

# Update system time and configure NTP
echo "Updating system time..."
rpm -ivh http://mirrors.wlnmp.com/centos/wlnmp-release-centos.noarch.rpm
yum install ntpdate -y
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
echo 'Asia/Shanghai' > /etc/timezone
ntpdate time2.aliyun.com
if ! crontab -l | grep "ntpdate" &>/dev/null; then
    (echo "*/5 * * * * /usr/sbin/ntpdate ntp.aliyun.com >/dev/null 2>&1"; crontab -l) | crontab
fi

# Check if ulimit -SHn 65535 is set
echo "Checking ulimit -SHn..."
if ! ulimit -n | grep "65535" &>/dev/null; then
  echo "Setting ulimit -SHn to 65535..."
  ulimit -SHn 65535
  cat >> /etc/security/limits.conf << EOF
* soft nofile 65536
* hard nofile 131072
* soft nproc  65535
* hard nproc  655350
* soft memlock unlimited
* hard memlock unlimited
EOF
fi

# Install ipvsadm, ipset, sysstat, conntrack, libseccomp
echo "Checking ipvsadm..."
if ! command -v ipvsadm &> /dev/null; then
  echo "Installing ipvsadm and other dependencies..."
  yum install ipvsadm ipset sysstat conntrack libseccomp -y
  cat >> /etc/modules-load.d/ipvs.conf << EOF
ip_vs
ip_vs_lc
ip_vs_wlc
ip_vs_rr
ip_vs_wrr
ip_vs_lblc
ip_vs_lblcr
ip_vs_dh
ip_vs_sh
ip_vs_fo
ip_vs_nq
ip_vs_sed
ip_vs_ftp
ip_vs_sh
nf_conntrack
ip_tables
ip_set
xt_set
ipt_set
ipt_rpfilter
ipt_REJECT
ipip
EOF
  systemctl enable --now systemd-modules-load.service
fi

# Configure sysctl settings
echo "Configuring sysctl settings..."
cat <<EOF > /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
fs.may_detach_mounts = 1
net.ipv4.conf.all.route_localnet = 1
vm.overcommit_memory=1
vm.panic_on_oom=0
fs.inotify.max_user_watches=89100
fs.file-max=52706963
fs.nr_open=52706963
net.netfilter.nf_conntrack_max=2310720

net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_keepalive_intvl =15
net.ipv4.tcp_max_tw_buckets = 36000
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_max_orphans = 327680
net.ipv4.tcp_orphan_retries = 3
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.ip_conntrack_max = 65536
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_timestamps = 0
net.core.somaxconn = 16384
EOF

sysctl --system

# Check if the kernel version is lower than 5
kernel_version=$(uname -r | awk -F'.' '{print $1}')
required_kernel_version=5

if [[ $kernel_version -lt $required_kernel_version ]]; then
  echo "Updating kernel to version 5 or higher..."
  yum update -y --exclude=kernel*
  cd /root
  wget http://193.49.22.109/elrepo/kernel/el7/x86_64/RPMS/kernel-ml-5.18.15-1.el7.elrepo.x86_64.rpm
  wget http://193.49.22.109/elrepo/kernel/el7/x86_64/RPMS/kernel-ml-devel-5.18.15-1.el7.elrepo.x86_64.rpm
  yum localinstall -y kernel-ml*
  grub2-set-default 0 && grub2-mkconfig -o /etc/grub2.cfg
  grubby --args="user_namespace.enable=1" --update-kernel="$(grubby --default-kernel)"
  echo "Rebooting the system..."
  reboot
fi

echo "Environment setup completed."