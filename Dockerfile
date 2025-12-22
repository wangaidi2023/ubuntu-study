FROM ubuntu:25.04

# 构建参数：传递 root 密码
ARG ROOT_PASSWORD=Sykes123
# 环境变量配置
ENV TZ=Asia/Shanghai
ENV SHELL=/bin/bash
ENV DEBIAN_FRONTEND=noninteractive
# 国内源加速（可选，解决 apt/pip 下载慢）
ENV PIP_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple

# 步骤1：替换 Ubuntu 源为国内镜像（解决 apt 下载慢）
RUN sed -i 's/ports.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list && \
    sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list

# 步骤2：更新 apt 并安装基础工具（替换废弃的 net-tools 为 iproute2）
# 关键：每行末尾加续行符 \，最后一个包后不加
RUN apt update && apt install -y --no-install-recommends \
    tzdata \
    bash-completion \
    ca-certificates \
    curl \
    wget \
    git \
    vim \
    nano \
    iproute2 \
    iputils-ping \
    telnet \
    python3 \
    python3-pip \
    gcc \
    make \
    openssh-server \
    supervisor \
    && apt clean && rm -rf /var/lib/apt/lists/*

# 步骤3：安装 ttyd（指定具体版本，避免 latest 链接失效）
RUN wget -qO /usr/local/bin/ttyd https://github.com/tsl0922/ttyd/releases/download/1.7.3/ttyd.x86_64 && \
    chmod +x /usr/local/bin/ttyd && \
    # 验证 ttyd 是否安装成功
    ttyd -v || echo "ttyd 安装失败，请检查下载链接"

# 步骤4：安装 Python 包（分开安装，便于定位依赖问题）
RUN pip3 install --upgrade pip && \
    pip3 install --no-cache-dir jupyterlab && \
    pip3 install --no-cache-dir akshare && \
    # 验证安装
    jupyter --version || echo "Jupyter 安装失败" && \
    python3 -c "import akshare; print(akshare.__version__)" || echo "akshare 安装失败"

# 步骤5：配置 SSH（适配 Ubuntu 25.04 配置语法）
RUN sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    # 设置 root 密码
    echo "root:${ROOT_PASSWORD}" | chpasswd && \
    # 创建 SSH 运行目录
    mkdir -p /var/run/sshd && \
    # 验证 SSH 配置
    sshd -t || echo "SSH 配置语法错误"

# 步骤6：创建工作目录和配置目录
RUN mkdir -p /etc/supervisor /study && \
    unset DEBIAN_FRONTEND

# 复制 supervisord 配置文件（注释单独换行）
COPY supervisord.conf /etc/supervisor/supervisord.conf

# 暴露端口
EXPOSE 22/tcp 7681/tcp 8888/tcp

# 启动 supervisord
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]
