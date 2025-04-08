#!/bin/bash
# 保存为 get_system_info.sh
# 大家根据用户名更改桌面路径
DESKTOP_PATH="/home/user/桌面"


# 尝试获取主机序列号
SERIAL_NUMBER=$(sudo dmidecode -s system-serial-number 2>/dev/null | grep -v "^#" | tr -d '[:space:]')
if [ -z "$SERIAL_NUMBER" ] || [ "$SERIAL_NUMBER" == "NotSpecified" ] || [ "$SERIAL_NUMBER" == "None" ]; then
    SERIAL_NUMBER="System_Info_$(date '+%Y%m%d_%H%M%S')"
else
    # 清理序列号中的特殊字符，确保能作为文件名
    SERIAL_NUMBER=$(echo "$SERIAL_NUMBER" | tr -cd '[:alnum:]-_')
fi

# 创建输出文件
OUTPUT_FILE="$DESKTOP_PATH/${SERIAL_NUMBER}.txt"

# 写入文件头部信息
echo "====== 系统信息报告 ======" > "$OUTPUT_FILE"
echo "生成时间: $(date '+%Y-%m-%d %H:%M:%S')" >> "$OUTPUT_FILE"
echo "文件名使用序列号: ${SERIAL_NUMBER}" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 重新获取序列号并格式化输出（之前获取的做文件名的可能被清理过）
SERIAL_NUMBER=$(sudo dmidecode -s system-serial-number 2>/dev/null | grep -v "^#")
if [ -z "$SERIAL_NUMBER" ]; then
    SERIAL_NUMBER="未获取到"
fi

# 1. 计算机信息
echo "===== 计算机信息 =====" >> "$OUTPUT_FILE"
echo "计算机序列号: $SERIAL_NUMBER" >> "$OUTPUT_FILE"
echo "制造商: $(sudo dmidecode -s system-manufacturer 2>/dev/null | grep -v '^#')" >> "$OUTPUT_FILE"
echo "产品名称: $(sudo dmidecode -s system-product-name 2>/dev/null | grep -v '^#')" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 2. BIOS信息
echo "===== BIOS信息 =====" >> "$OUTPUT_FILE"
echo "BIOS厂商: $(sudo dmidecode -s bios-vendor 2>/dev/null | grep -v '^#')" >> "$OUTPUT_FILE"
echo "BIOS版本: $(sudo dmidecode -s bios-version 2>/dev/null | grep -v '^#')" >> "$OUTPUT_FILE"
echo "BIOS日期: $(sudo dmidecode -s bios-release-date 2>/dev/null | grep -v '^#')" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 3. 网络信息
echo "===== 网络信息 =====" >> "$OUTPUT_FILE"
echo "MAC地址信息:" >> "$OUTPUT_FILE"
ip -o link show | awk '{print $2,$(NF-2)}' | grep -v "lo:" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 4. CPU信息
echo "===== CPU信息 =====" >> "$OUTPUT_FILE"
lscpu | grep "Model name" | sed 's/Model name:/CPU型号:/' >> "$OUTPUT_FILE"
echo "核心数量: $(nproc)" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 5. 内存信息
echo "===== 内存信息 =====" >> "$OUTPUT_FILE"
free -h | awk '/Mem/{print "总内存: "$2, "已用: "$3, "可用: "$4}' >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 6. 硬盘信息
echo "===== 硬盘信息 =====" >> "$OUTPUT_FILE"
DISKS=$(lsblk -d -o NAME,ROTA | grep -v NAME | awk '{print $1}')
COUNT=0
for DISK in $DISKS; do
    	if [[ $DISK =~ ^(sd|nvme|hd) ]]; then
        MODEL=$(cat /sys/block/$DISK/device/model 2>/dev/null | tr -d '\n' | sed 's/[[:space:]]*$//')
        SERIAL=$(cat /sys/block/$DISK/device/serial 2>/dev/null | tr -d '\n')
        ROTATIONAL=$(cat /sys/block/$DISK/queue/rotational 2>/dev/null)
        SIZE=$(lsblk -b -d -o SIZE /dev/$DISK | awk 'NR>1{print $1/1024/1024/1024"GB"}')
    
        if [ -n "$SERIAL" ]; then
            COUNT=$((COUNT+1))
            DISK_TYPE="机械硬盘"
            [ "$ROTATIONAL" == "0" ] && DISK_TYPE="固态硬盘"
            
            echo "硬盘${COUNT}: $DISK_TYPE" >> "$OUTPUT_FILE"
            echo "设备: /dev/$DISK" >> "$OUTPUT_FILE"
            echo "容量: $SIZE" >> "$OUTPUT_FILE"
            echo "品牌型号: $MODEL" >> "$OUTPUT_FILE"
            echo "序列号: $SERIAL" >> "$OUTPUT_FILE"
            echo "" >> "$OUTPUT_FILE"
        fi
    fi
done

echo "找到 ${COUNT} 块硬盘" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 7. 系统摘要
echo "===== 系统摘要 =====" >> "$OUTPUT_FILE"
echo "主机名: $(hostname)" >> "$OUTPUT_FILE"
echo "操作系统: $(lsb_release -d | cut -f2-)" >> "$OUTPUT_FILE"
echo "内核版本: $(uname -r)" >> "$OUTPUT_FILE"
echo "系统架构: $(arch)" >> "$OUTPUT_FILE"

# 设置文件权限
chmod 666 "$OUTPUT_FILE"

echo ""
echo "系统信息已保存到: $OUTPUT_FILE"
