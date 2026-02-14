# loveli 自动签到

[loveli.com.cn](http://www.loveli.com.cn/) 网安靶场每日自动签到脚本，部署到服务器后每天自动登录并签到获取积分。

## 功能

- 每天定时自动签到，无需手动操作
- 一键部署到 Ubuntu 服务器
- 自动记录签到日志
- 支持自定义签到时间
- 重复签到自动识别跳过

## 快速开始

### 1. 获取 Token

关注 loveli 微信公众号，输入 `bug`，会返回你的 Token。

### 2. 部署到服务器

SSH 登录你的 Ubuntu 服务器，执行以下命令：

```bash
# 下载项目
git clone https://github.com/wenject/loveli-checkin.git
cd loveli-checkin

# 一键部署
bash deploy.sh
```

按提示输入 Token 和签到时间就行了，部署完会自动执行一次签到测试。

### 3. 手动部署（不用脚本）

如果你想手动配置：

```bash
# 安装依赖
sudo apt update && sudo apt install -y python3 python3-pip
pip3 install requests

# 测试签到
CHECKIN_TOKEN=你的token python3 checkin.py

# 添加定时任务（每天 8:00 签到）
crontab -e
# 添加这一行：
# 0 8 * * * cd /path/to/loveli-checkin && CHECKIN_TOKEN=你的token python3 checkin.py >> logs/cron.log 2>&1
```

## 项目结构

```
loveli-checkin/
├── checkin.py      # 签到脚本（核心）
├── deploy.sh       # 一键部署脚本
├── README.md       # 说明文档
├── LICENSE         # 开源协议
├── .gitignore      # Git 忽略规则
└── logs/           # 日志目录（自动创建）
    └── checkin.log
```

## 常用命令

```bash
# 手动执行签到
bash ~/loveli-checkin/run.sh

# 查看签到日志
cat ~/loveli-checkin/logs/checkin.log

# 查看定时任务
crontab -l

# 修改 Token
nano ~/loveli-checkin/.env

# 卸载
crontab -l | grep -v loveli | crontab - && rm -rf ~/loveli-checkin
```

## 环境变量

| 变量名               | 说明               | 默认值                      |
| -------------------- | ------------------ | --------------------------- |
| `CHECKIN_TOKEN`      | 登录 Token（必填） | -                           |
| `CHECKIN_TARGET_URL` | 目标网站地址       | `http://www.loveli.com.cn/` |

## 签到日志示例

```
2026-02-15T08:00:01 - INFO - ===== 开始签到 2026-02-15 =====
2026-02-15T08:00:01 - INFO - 正在登录...
2026-02-15T08:00:02 - INFO - 登录成功
2026-02-15T08:00:02 - INFO - 正在签到...
2026-02-15T08:00:03 - INFO - 签到成功: 签到成功，连续签到2天，获得0.32积分
```

## 系统要求

- Ubuntu 18.04+ （其他 Linux 发行版也可以）
- Python 3.6+
- 网络能访问 loveli.com.cn

## 常见问题

**Q: Token 怎么获取？**
A: 关注 loveli 微信公众号，发送 `bug`，会返回你的 Token。

**Q: Token 会过期吗？**
A: 如果签到失败，检查日志，可能需要重新获取 Token。修改 `~/loveli-checkin/.env` 文件中的 Token 即可。

**Q: 怎么修改签到时间？**
A: 运行 `crontab -e`，修改定时任务中的时间。格式是 `分 时 * * *`，比如 `30 9 * * *` 表示每天 9:30。

**Q: 怎么确认签到成功了？**
A: 查看日志 `cat ~/loveli-checkin/logs/checkin.log`，或者登录网站查看积分。

## License

MIT
