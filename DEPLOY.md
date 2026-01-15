# Jellyflix 部署指南

## 1. 构建Web版本

在jellyflix项目目录运行：

```bash
nix develop --command flutter build web --release
```

构建产物在 `build/web/` 目录。

## 2. 上传到服务器

将构建文件上传到服务器的 `/var/www/jellyflix` 目录：

```bash
# 使用rsync上传
rsync -avz --delete build/web/ your-server:/var/www/jellyflix/
```

或者使用scp：

```bash
scp -r build/web/* your-server:/var/www/jellyflix/
```

## 3. 应用NixOS配置

在服务器上（或远程）运行：

```bash
cd ~/nixos-config
sudo nixos-rebuild switch --flake .#hetzner-server
```

## 4. 访问

配置完成后，可以通过以下地址访问：

- **Jellyflix**: https://movies.dzming.li
- **Jellyfin**: https://media.dzming.li

## 配置说明

在 `hetzner-server/jellyfin.nix` 中添加了以下配置：

1. **Caddy虚拟主机**: `movies.dzming.li` 反向代理到端口 8090
2. **systemd服务**: `jellyflix-web` 使用Python简单HTTP服务器提供静态文件
3. **用户和目录**: 创建 `jellyflix` 用户和 `/var/www/jellyflix` 目录

## 自动化部署脚本

可以创建一个部署脚本 `deploy.sh`：

```bash
#!/usr/bin/env bash
set -e

echo "🏗️  Building Jellyflix web..."
nix develop --command flutter build web --release

echo "📤 Uploading to server..."
rsync -avz --delete build/web/ hetzner-server:/var/www/jellyflix/

echo "🔄 Applying NixOS configuration..."
ssh hetzner-server "cd ~/nixos-config && sudo nixos-rebuild switch --flake .#hetzner-server"

echo "✅ Deployment complete!"
echo "🌐 Visit: https://movies.dzming.li"
```
