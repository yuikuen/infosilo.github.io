#!/bin/bash

source /etc/profile
source ~/.bash_profile

# 获取当前日期
current_date=$(date +%Y%m%d)
# 获取服务器名
current_hostname=$(hostname)
# 服务器IP地址
ip_add=$(/usr/sbin/ip addr | grep inet | grep -vE 'inet6|127.0.0.1' | awk '{print $2}' | head -1)

# 业务名称
service_name="MySQL"
# MySQL配置文件路径，登录密码
sql_config="/etc/my.cnf"

# 备份路径
bak_path="/opt/backup/mysql-ds"
# 备份文件
bak_file="bak_${current_date}.bak"
# 备份日志
log_file="${bak_path}/bak_note.log"

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

# 备份开始时间
start_time=$(date +"%Y-%m-%d %H:%M:%S")
echo "========================================================" >> ${log_file}
echo "MySQL备份开始时间：${start_time}" >> ${log_file}
mysqldump --defaults-file=${sql_config} --all-databases > "${bak_path}/${bak_file}"

# 检查备份结果
if [ $? -eq 0 ] && [ -s "${bak_path}/${bak_file}" ]; then
  # 输出备份结束时间
  end_time=$(date +"%Y-%m-%d %H:%M:%S")
  echo "MySQL备份结束时间：${end_time}" >> ${log_file}
  # 计算备份耗时时长
  start_timestamp=$(date -d "$start_time" +%s)
  end_timestamp=$(date -d "$end_time" +%s)
  duration=$((end_timestamp - start_timestamp))
  # 计算备份文件大小
  file_size=$(du -h "${bak_path}/${bak_file}" | awk '{print $1}')
  # 输出备份结果，最后发送至DingTalk
  echo "MySQL备份成功，备份文件：${bak_file} 备份大小：${file_size} 耗时：${duration}秒" >> ${log_file}
  ding_content="服务：${service_name}\n\n机器：${current_hostname}\n\n地址：${ip_add}\n\n文件：${bak_file}\n\n大小：${file_size}\n\n耗时：${duration}秒\n\n"
  SendMessageToDingding "${service_name}-数据备份【成功】" "${ding_content}"
else
  echo "MySQL备份失败" >> ${log_file}
  ding_content="服务：${service_name}\n\n机器：${current_hostname}\n\n地址：${ip_add}\n\n文件：${bak_file}\n\n大小：0\n\n"
  SendMessageToDingding "${service_name}-数据备份【失败】" "${ding_content}"
fi

## 删除备份目录下以肖前日期为准的前三天的备份文件
## # 输出当前日期
## current_date=$(date +%Y%m%d)
## echo "当前日期：${current_date}"
## 
## # 判断指定路径下是否存在 *.bak 文件
## bak_files=(${bak_path}/*.bak)
## if [ ${#bak_files[@]} -gt 0 ]; then
##   echo "删除 ${bak_path} 目录下以当前日期为准的前三天的备份文件：" >> ${log_file}
## 
##   # 删除以当前日期为准的前三天的备份文件
##   for ((i=1; i<=3; i++)); do
##     old_date=$(date -d "$i days ago" +%Y%m%d)
##     old_bak_file="bak_${old_date}.bak"
##     if [ -f "${bak_path}/${old_bak_file}" ]; then
##       rm "${bak_path}/${old_bak_file}"
##       echo "已删除文件：${old_bak_file}" >> ${log_file}
##     fi
##   done
## else
##   echo "${bak_path} 目录下没有备份文件"
## fi

## 保留当前日期的备份文件和前两天的备份文件，并删除其他备份文件
## 脚本将删除不符合保留条件的备份文件，保留当前日期的备份文件和前两天的备份文件。
# 输出当前日期
current_date=$(date +%Y%m%d)
echo "当前日期：${current_date}"

# 判断指定路径下是否存在 *.bak 文件
bak_files=(${bak_path}/*.bak)
if [ ${#bak_files[@]} -gt 0 ]; then
  echo "保留当前日期的备份文件，并且保留以当前日期为准的前两天备份文件，其余*.bak文件强制删除：" >> ${log_file}

  # 删除不符合保留条件的备份文件
  for bak_file in "${bak_files[@]}"; do
    file_date=$(basename "$bak_file" | sed 's/bak_//;s/\.bak//')
    if [[ $file_date -lt $(date -d '2 days ago' +%Y%m%d) || $file_date -gt $current_date ]]; then
      rm -rf "$bak_file"
      echo "已删除文件：$(basename "$bak_file")" >> ${log_file}
    fi
  done
else
  echo "${bak_path} 目录下没有备份文件" >> ${log_file}
fi