#!/bin/bash
# shell_name：auto_bak_gitlab.sh
# 该脚本用于自动备份 GitLab 配置和数据文件，复制至 Nas 共享目录($bak_path)，最后输出备份结果，发送至 DingTalk

# 脚本依赖
source /etc/profile
source ~/.bash_profile

## 服务信息
# 获取当前日期
current_date=$(date +%Y%m%d)
# 获取服务器名
current_hostname=$(hostname)
# 获取服务地址
current_ip=$(/usr/sbin/ip addr | grep inet | grep -vE 'inet6|127.0.0.1' | awk '{print $2}' | head -1)
# 业务名称
service_name="GitLab"

## 备份清单
# - 配置文件：/opt/cicd/gitlab/config/config_backup
# - 数据文件：/opt/cicd/gitlab/data/backups
# - 备份路径：/opt/backup/gitlab-ds
# - 日志文件：/opt/backup/gitlab-ds/bak_note.log
config_path="/opt/cicd/gitlab/config/config_backup"
data_path="/opt/cicd/gitlab/data/backups"
bak_path="/opt/backup/gitlab-ds"
log_file="${bak_path}/bak_note.log"

## 钉钉配置
# 机器人Webhook
webhook="https://oapi.dingtalk.com/robot/send?access_token=钉机器人获取"
# 发送消息函数
function SendMessageToDingding(){
    curl "$webhook" -H 'Content-Type: application/json' -d "
    {
        \"actionCard\": {
            \"title\": \"$1\", 
            \"text\": \"$2\", 
            \"hideAvatar\": \"0\", 
            \"btnOrientation\": \"0\", 
            \"btns\": [
                {
                    \"title\": \"$1\", 
                    \"actionURL\": \"\"
                }
            ]
        }, 
        \"msgtype\": \"actionCard\"
    }"
}

## 备份过程
# 开始时间
start_time=$(date +"%Y-%m-%d %H:%M:%S")
echo "========================================================" >> ${log_file}
echo "${service_name}备份开始时间：${start_time}" >> ${log_file}
# 备份配置&数据
# crontab不执行docker命令，因-it开启终端导致脚本无法执行；
docker exec gitlab-ce /bin/sh -c 'gitlab-ctl backup-etc && gitlab-backup create'

# 输出备份文件名称
#file_name="$(ls -t "${data_path}" | head -n1)"
latest_bak_config="${config_path}/$(ls -t "${config_path}" | head -n1)"
latest_bak_data="${data_path}/$(ls -t "${data_path}" | head -n1)"

# 判断备份文件是否存在，存在则复制至备份路径
if [ -f "$latest_bak_config" ] && [ -f "$latest_bak_data" ]; then
  # 复制操作
  cp -f "${latest_bak_config}" "${bak_path}"
  cp -f "${latest_bak_data}" "${bak_path}"
  # 输出备份结束时间
  end_time=$(date +"%Y-%m-%d %H:%M:%S")
  echo "${end_time}" >> ${log_file}
  # 计算备份耗时时长
  start_timestamp=$(date -d "$start_time" +%s)
  end_timestamp=$(date -d "$end_time" +%s)
  duration=$((end_timestamp - start_timestamp))
  # 计算备份文件大小
  file_size=$(du -h "${latest_bak_data}" | awk '{print $1}')
  # 获取文件名部分
  file_name=$(basename "${latest_bak_data}")
  # 截取文件名前缀
  file_prefix=${file_name%%_*}
  echo "GitLab备份成功，备份文件：${file_prefix} 备份大小：${file_size} 耗时：${duration}秒" >> ${log_file}
  ding_content="服务：${service_name}\n\n机器：${current_hostname}\n\n地址：${current_ip}\n\n文件：${file_prefix}\n\n大小：${file_size}\n\n耗时：${duration}秒\n\n"
  SendMessageToDingding "${service_name}-数据备份【成功】" " ${ding_content}"
else
  echo "GitLab备份失败" >> ${log_file}
  ding_content="服务：${service_name}\n\n机器：${current_hostname}\n\n地址：${current_ip}\n\n"
  SendMessageToDingding "${service_name}-数据备份【失败】" "${ding_content}"
fi
