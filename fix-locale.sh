#!/bin/bash

# 修复locale警告的脚本

# 清理现有的locale设置
unset LC_ALL
unset LANG
unset LC_CTYPE

# 设置正确的locale
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

# 更新bashrc
grep -q "LC_ALL=C.UTF-8" ~/.bashrc || echo "export LC_ALL=C.UTF-8" >> ~/.bashrc
grep -q "LANG=C.UTF-8" ~/.bashrc || echo "export LANG=C.UTF-8" >> ~/.bashrc

# 移除可能导致问题的LC_CTYPE设置
sed -i '/export LC_CTYPE/d' ~/.bashrc

echo "Locale已修复，请重新登录或运行 'source ~/.bashrc'"
