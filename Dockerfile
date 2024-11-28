# 使用官方的 Node.js 镜像作为构建阶段基础镜像
FROM node:alpine

# 设置工作目录
WORKDIR /app

# 复制 package.json 和 package-lock.json（如果有的话）
COPY package*.json ./

# 安装项目依赖
RUN npm install

# 复制项目文件到工作目录
COPY server.js index.html ./

# 安装 tdl
RUN apk add --no-cache curl && \
    set -eux; \
    OS="Linux"; \
    ARCH="$(uname -m)"; \
    OWNER="iyear" \
    REPO="tdl" \
    LOCATION="/usr/local/bin" \
    VERSION=$(curl --silent "https://api.github.com/repos/$OWNER/$REPO/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'); \
    echo "Target version: $VERSION"; \
    if [ "$ARCH" = "x86_64" ]; then ARCH="64bit"; \
    elif [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; \
    elif [ "$ARCH" = "armv7l" ]; then ARCH="armv7"; \
    else echo "Unsupported architecture: $ARCH"; exit 1; fi; \
    URL=https://github.com/$OWNER/$REPO/releases/download/$VERSION/${REPO}_${OS}_$ARCH.tar.gz; \
    echo "Downloading $REPO from $URL"; \
    curl -sL "$URL" | tar -xz && \
    mv $REPO $LOCATION/$REPO && \
    chmod +x $LOCATION/$REPO && \
    echo "$REPO installed successfully! Location: $LOCATION/$REPO"; \
    echo "Run '$REPO' to get started"; \
    echo "To get started with tdl, please visit https://docs.iyear.me/tdl"

# 暴露应用运行的端口
EXPOSE 3000

# 启动应用
CMD ["node", "server.js"]
