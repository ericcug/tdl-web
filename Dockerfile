# 使用官方的 Node.js 镜像作为构建阶段基础镜像
FROM node:alpine AS build

# 设置工作目录
WORKDIR /app

# 复制 package.json 和 package-lock.json（如果有的话）
COPY package*.json ./

# 安装项目依赖
RUN npm install --production

# 复制项目文件到工作目录
COPY server.js index.html ./

# 使用更精简的基础镜像作为生产阶段基础镜像
FROM alpine:latest

# 设置必要的依赖
RUN apk add --no-cache wget curl

# 复制构建阶段的应用文件
COPY --from=build /app /app

# 环境变量
ENV OWNER="iyear" \
    REPO="tdl" \
    LOCATION="/usr/local/bin" \
    VERSION=""

# 安装 tdl
RUN set -eux; \
    if [ -z "$VERSION" ]; then \
        VERSION=$(curl --silent "https://api.github.com/repos/$OWNER/$REPO/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'); \
    fi; \
    echo "Target version: $VERSION"; \
    OS="Linux"; \
    ARCH="$(uname -m)"; \
    if [ "$ARCH" = "x86_64" ]; then ARCH="64bit"; \
    elif [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; \
    elif [ "$ARCH" = "armv7l" ]; then ARCH="armv7"; \
    else echo "Unsupported architecture: $ARCH"; exit 1; fi; \
    URL=https://github.com/$OWNER/$REPO/releases/download/$VERSION/${REPO}_${OS}_$ARCH.tar.gz; \
    echo "Downloading $REPO from $URL"; \
    wget -q --show-progress -O - "$URL" | tar -xz && \
    mv $REPO $LOCATION/$REPO && \
    chmod +x $LOCATION/$REPO && \
    echo "$REPO installed successfully! Location: $LOCATION/$REPO"; \
    echo "Run '$REPO' to get started"; \
    echo "To get started with tdl, please visit https://docs.iyear.me/tdl"

# 设置工作目录
WORKDIR /app

# 暴露应用运行的端口
EXPOSE 8765

# 启动应用
CMD ["node", "server.js"]
