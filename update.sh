#!/usr/bin/env bash
# Socks5TzspBridge(数据中转器) 一键管理: 更新 + 启动 / 停止 / 重启 / 状态
#   ./update.sh            一键: git pull -> 解压更新 -> 后台启动
#   ./update.sh start      仅启动(若在跑则先停旧)
#   ./update.sh stop       停止后台进程
#   ./update.sh restart    停止 -> 启动(不拉取)
#   ./update.sh status     查看运行状态与最近日志
# 解码器在别的机器:  export TZSP=解码器IP:37008; ./update.sh
set -e
cd "$(dirname "$0")"

NAME="Socks5TzspBridge"
ZIP="$NAME-linux-x64.zip"
INSTALL_DIR="$PWD/bridge"
PID_FILE="$INSTALL_DIR/$NAME.pid"
LOG_FILE="$INSTALL_DIR/$NAME.log"
TZSP="${TZSP:-127.0.0.1:37008}"     # 同机解码器默认; 跨机改这里

say() { printf '\033[36m[%s]\033[0m %s\n' "$(date +%H:%M:%S)" "$*"; }
err() { printf '\033[31m[error]\033[0m %s\n' "$*" >&2; }

is_running() { [ -f "$PID_FILE" ] && [ -n "$(cat "$PID_FILE" 2>/dev/null)" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; }

stop() {
    if is_running; then
        local pid; pid="$(cat "$PID_FILE")"
        say "停止旧进程 pid=$pid ..."
        kill -INT "$pid" 2>/dev/null || true        # SIGINT 触发 .NET 优雅关闭
        for _ in $(seq 1 25); do kill -0 "$pid" 2>/dev/null || break; sleep 0.2; done
        if kill -0 "$pid" 2>/dev/null; then
            say "进程未退出, 强制 kill -9"
            kill -9 "$pid" 2>/dev/null || true
        fi
        rm -f "$PID_FILE"
        say "已停止"
    else
        say "没有运行中的进程(pidfile 不存在或已退出)"
    fi
}

start() {
    stop
    if [ ! -x "$INSTALL_DIR/$NAME" ]; then
        err "缺少 $INSTALL_DIR/$NAME —— 请先执行 ./update.sh 做首次解压"
        exit 1
    fi
    say "启动 $NAME  (TZSP=$TZSP) ..."
    ( cd "$INSTALL_DIR" && exec nohup "./$NAME" --tzsp "$TZSP" >"$LOG_FILE" 2>&1 & echo $! > "$PID_FILE" )
    sleep 1
    if is_running; then
        say "已启动 pid=$(cat "$PID_FILE")   日志: $LOG_FILE"
    else
        err "启动失败, 最近日志:"
        tail -n 8 "$LOG_FILE" 2>/dev/null | sed 's/^/    /'
        exit 1
    fi
}

update() {
    say "[更新] git pull --ff-only ..."
    git pull --ff-only
    if [ ! -f "$ZIP" ]; then
        err "仓库缺少 $ZIP"
        exit 1
    fi
    mkdir -p "$INSTALL_DIR"
    say "[更新] 解压 $ZIP -> $INSTALL_DIR ..."
    unzip -o "$ZIP" -d "$INSTALL_DIR"
    chmod +x "$INSTALL_DIR/$NAME"
    say "[更新] 完成"
}

status() {
    if is_running; then
        local pid; pid="$(cat "$PID_FILE")"
        say "运行中: $INSTALL_DIR/$NAME  (pid=$pid)"
        ps -o pid,etime,cmd -p "$pid" --no-headers 2>/dev/null || true
    else
        say "未运行 (pidfile: $PID_FILE)"
    fi
    if [ -f "$LOG_FILE" ]; then
        say "最近日志($LOG_FILE):"
        tail -n 5 "$LOG_FILE" | sed 's/^/    /'
    fi
}

case "${1:-}" in
    start)   start ;;
    stop)    stop ;;
    restart) start ;;
    status)  status ;;
    ""|run|update) update; start ;;
    *) err "未知参数: $1 (支持: start / stop / restart / status / 空=一键更新并启动)"; exit 1 ;;
esac
