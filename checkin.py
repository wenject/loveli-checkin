#!/usr/bin/env python3
"""
loveli.com.cn 自动签到脚本
用法: python3 checkin.py
配置: 设置环境变量 CHECKIN_TOKEN 或修改下方 TOKEN
"""

import os
import re
import sys
import json
import logging
from datetime import datetime
from pathlib import Path

import requests

# ============ 配置 ============
TOKEN = os.environ.get("CHECKIN_TOKEN", "")
TARGET_URL = os.environ.get("CHECKIN_TARGET_URL", "http://www.loveli.com.cn/")
LOG_DIR = Path(__file__).parent / "logs"
# ==============================

USER_AGENT = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
    "AppleWebKit/537.36 (KHTML, like Gecko) "
    "Chrome/120.0.0.0 Safari/537.36"
)


def setup_logging():
    LOG_DIR.mkdir(exist_ok=True)
    log_file = LOG_DIR / "checkin.log"
    fmt = "%(asctime)s - %(levelname)s - %(message)s"
    logging.basicConfig(
        level=logging.INFO,
        format=fmt,
        datefmt="%Y-%m-%dT%H:%M:%S",
        handlers=[
            logging.StreamHandler(),
            logging.FileHandler(log_file, encoding="utf-8"),
        ],
    )


def login(token: str) -> requests.Session:
    """登录并返回已认证的 Session"""
    session = requests.Session()
    session.headers.update({"User-Agent": USER_AGENT})

    login_url = TARGET_URL.rstrip("/") + "/login"

    # 获取 CSRF token
    resp = session.get(login_url, timeout=30)
    resp.raise_for_status()
    match = re.search(r'csrfmiddlewaretoken"\s+value="([^"]+)"', resp.text)
    if not match:
        raise Exception("无法获取 CSRF token")

    # POST 登录
    data = {
        "csrfmiddlewaretoken": match.group(1),
        "token": token,
        "url": "",
        "agree": "on",
    }
    resp = session.post(login_url, data=data, headers={"Referer": login_url}, timeout=30)
    resp.raise_for_status()

    if "/logout" not in resp.text:
        raise Exception("登录失败：页面中未找到退出链接")

    return session


def checkin(session: requests.Session) -> dict:
    """执行签到，返回 JSON 结果"""
    checkin_url = TARGET_URL.rstrip("/") + "/302"
    headers = {
        "X-Requested-With": "XMLHttpRequest",
        "Referer": TARGET_URL,
    }
    resp = session.get(checkin_url, headers=headers, timeout=30)
    resp.raise_for_status()
    return resp.json()


def main():
    setup_logging()
    logger = logging.getLogger("checkin")

    token = TOKEN
    if not token:
        logger.error("未设置 CHECKIN_TOKEN 环境变量")
        sys.exit(1)

    logger.info("===== 开始签到 %s =====", datetime.now().strftime("%Y-%m-%d"))

    try:
        logger.info("正在登录...")
        session = login(token)
        logger.info("登录成功")

        logger.info("正在签到...")
        result = checkin(session)
        msg = result.get("msg", "")
        success = result.get("success", 0)

        if success == 1:
            logger.info("签到成功: %s", msg)
        elif "已签到" in msg:
            logger.info("今天已签到: %s", msg)
        else:
            logger.warning("签到异常: %s", json.dumps(result, ensure_ascii=False))

    except Exception as e:
        logger.error("签到失败: %s", e)
        sys.exit(1)


if __name__ == "__main__":
    main()
