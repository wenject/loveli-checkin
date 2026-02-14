#!/bin/bash
# ============================================
# loveli.com.cn 自动签到 一键部署脚本
# 用法: bash deploy.sh
# ============================================

set -e

echo "=============================="
echo "  loveli 自动签到 一键部署"
echo "=============================="
echo ""

# 1. 获取 token
if [ -z "$CHECKIN_TOKEN" ]; then
    read -p "请输入你的 Token: " CHECKIN_TOKEN
fi

if [ -z "$CHECKIN_TOKEN" ]; then
    echo "错误: Token 不能为空"
    exit 1
fi

# 2. 设置签到时间（默认每天 8:00）
read -p "每天几点签到？(默认 08:00，直接回车使用默认): " CHECKIN_TIME
CHECKIN_TIME=${CHECKIN_TIME:-08:00}

# 解析小时和分钟
HOUR=$(echo "$CHECKIN_TIME" | cut -d: -f1)
MINUTE=$(echo "$CHECKIN_TIME" | cut -d: -f2)

# 3. 安装目录
INSTALL_DIR="$HOME/loveli-checkin"
echo ""
echo "安装目录: $INSTALL_DIR"
echo "签到时间: 每天 $CHECKIN_TIME"
echo ""

# 4. 安装 Python3 和 pip（如果没有）
if ! command -v python3 &> /dev/null; then
    echo "正在安装 Python3..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update -qq && sudo apt-get install -y -qq python3 python3-pip
    elif command -v yum &> /dev/null; then
        sudo yum install -y python3 python3-pip
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y python3 python3-pip
    else
        echo "错误: 无法自动安装 Python3，请手动安装后重试"
        exit 1
    fi
fi

# 5. 创建安装目录
mkdir -p "$INSTALL_DIR/logs"

# 6. 下载签到脚本（如果是本地部署就直接复制）
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/checkin.py" ]; then
    cp "$SCRIPT_DIR/checkin.py" "$INSTALL_DIR/checkin.py"
else
    echo "错误: 找不到 checkin.py，请确保和 deploy.sh 在同一目录"
    exit 1
fi

# 7. 安装依赖
if ! python3 -c "import requests" 2>/dev/null; then
    echo "正在安装 requests 库..."
    pip3 install requests --quiet 2>/dev/null \
        || python3 -m pip install requests --quiet 2>/dev/null \
        || pip3 install requests --quiet --break-system-packages 2>/dev/null \
        || sudo apt-get install -y -qq python3-requests 2>/dev/null
fi

# 8. 写入环境变量配置文件
cat > "$INSTALL_DIR/.env" << EOF
CHECKIN_TOKEN=$CHECKIN_TOKEN
EOF
chmod 600 "$INSTALL_DIR/.env"

# 9. 创建运行脚本
cat > "$INSTALL_DIR/run.sh" << 'RUNEOF'
#!/bin/bash
cd "$(dirname "$0")"
source .env
export CHECKIN_TOKEN
python3 checkin.py
RUNEOF
chmod +x "$INSTALL_DIR/run.sh"

# 10. 设置 crontab 定时任务
CRON_JOB="$MINUTE $HOUR * * * cd $INSTALL_DIR && bash run.sh >> logs/cron.log 2>&1"

# 移除旧的签到任务（如果有）
(crontab -l 2>/dev/null | grep -v "loveli-checkin" | grep -v "# loveli") | crontab - 2>/dev/null || true

# 添加新任务
(crontab -l 2>/dev/null; echo "# loveli auto checkin"; echo "$CRON_JOB") | crontab -

echo ""
echo "=============================="
echo "  部署完成！"
echo "=============================="
echo ""
echo "安装位置: $INSTALL_DIR"
echo "签到时间: 每天 $HOUR:$MINUTE"
echo "日志文件: $INSTALL_DIR/logs/checkin.log"
echo ""
echo "常用命令:"
echo "  手动签到:   bash $INSTALL_DIR/run.sh"
echo "  查看日志:   cat $INSTALL_DIR/logs/checkin.log"
echo "  查看定时:   crontab -l"
echo "  卸载:       crontab -l | grep -v loveli | crontab - && rm -rf $INSTALL_DIR"
echo ""

# 11. 立即执行一次测试
read -p "是否立即执行一次签到测试？(y/n, 默认 y): " DO_TEST
DO_TEST=${DO_TEST:-y}
if [ "$DO_TEST" = "y" ] || [ "$DO_TEST" = "Y" ]; then
    echo ""
    echo "正在执行签到测试..."
    bash "$INSTALL_DIR/run.sh"
fi
