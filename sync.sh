# 源码在用户家目录（git仓库）
# cd ~/ice-wiki-public
git pull
mkdocs build

# 同步静态产物到 /var/www/ice-wiki-public
rsync -av --delete ./site/ /var/www/ice-wiki-public/



