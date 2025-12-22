FROM ubuntu:25.04

# 环境变量配置
ENV TZ=Asia/Shanghai
ENV ROOT_PASSWORD=Sykes123
ENV SHELL=/bin/bash
# 非交互式安装，避免 tzdata 弹框（注释单独换行，避免解析错误）
ENV DEBIAN_FRONTEND=noninteractive

# 安装基础工具 + SSH + ttyd + Jupyter + 进程管理工具
RUN apt update && apt install -y --no-install-recommends \
    # 基础工具
    tzdata \
    bash-completion \
    ca-certificates \
    curl \
    wget \
    git \
    vim \
    nano \
    net-tools \
    iputils-ping \
    telnet \
    python3 \
    python3-pip \
    gcc \
    make \
    # SSH 服务
    openssh-server \
    # 进程管理工具（用于管理多服务）
    supervisor \
    # ttyd 依赖（ttyd 基于 libwebsockets，部分系统需预装）
    #libwebsockets16 \
    && apt clean && rm -rf /var/lib/apt/lists/* \
    # 安装 ttyd（从官方下载预编译二进制包，Ubuntu minimal 无官方 apt 源）
    && wget -qO /usr/local/bin/ttyd https://github.com/tsl0922/ttyd/releases/latest/download/ttyd.x86_64 \
    && chmod +x /usr/local/bin/ttyd \
    # 安装 Jupyter 和 akshare
    && pip3 install --no-cache-dir akshare jupyterlab \
    # SSH 配置
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && echo "root:${ROOT_PASSWORD}" | chpasswd \
    && mkdir -p /var/run/sshd \
    # 创建 supervisord 配置目录
    && mkdir -p /etc/supervisor \
    && mkdir -p /study \
    # 清理非交互式环境变量（可选，恢复默认行为）
    && unset DEBIAN_FRONTEND

# 复制 supervisord 配置文件（管理 SSH、ttyd、Jupyter 进程）
COPY supervisord.conf /etc/supervisor/supervisord.conf

# 暴露端口：SSH(22) + ttyd(7681) + Jupyter(8888)
EXPOSE 22/tcp 7681/tcp 8888/tcp

# 启动 supervisord 管理所有服务
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]


