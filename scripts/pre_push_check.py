#!/usr/bin/env python3
"""
OpenFaith Flutter 推送前验证脚本
用法: python pre_push_check.py
在推送任何代码到 GitHub 之前运行此脚本，检查：
1. Flutter 代码是否有编译错误（flutter analyze）
2. shorebird-patch.yml 版本号是否与 pubspec.yaml 一致
3. 是否有未提交的修改
"""
import subprocess
import sys
import re
import os

PROJECT_DIR = r"C:\OpenFaith-Flutter\openfaith_app"
os.chdir(PROJECT_DIR)

errors = []
warnings = []

# 1. 检查 flutter analyze
print("🔍 [1/3] Flutter 代码静态分析...")
result = subprocess.run(
    ["flutter", "analyze", "--no-pub"],
    capture_output=True, text=True, timeout=120
)
if result.returncode != 0:
    # 提取错误行
    error_lines = [l for l in result.stdout.split('\n') if 'error' in l.lower() and '•' in l]
    if error_lines:
        errors.append(f"Flutter 编译错误 ({len(error_lines)} 个):")
        for line in error_lines[:5]:
            errors.append(f"  {line.strip()}")
else:
    print("  ✅ 无编译错误")

# 2. 检查版本号一致性
print("🔍 [2/3] 版本号一致性检查...")
with open("pubspec.yaml", "r", encoding="utf-8") as f:
    pubspec = f.read()
pub_version = re.search(r'^version:\s*(.+)$', pubspec, re.MULTILINE)
if pub_version:
    pub_ver = pub_version.group(1).strip()
    print(f"  pubspec.yaml 版本: {pub_ver}")
    
    workflow_path = ".github/workflows/shorebird-patch.yml"
    if os.path.exists(workflow_path):
        with open(workflow_path, "r", encoding="utf-8") as f:
            wf_content = f.read()
        wf_version = re.search(r'release-version:\s*"([^"]+)"', wf_content)
        if wf_version:
            wf_ver = wf_version.group(1)
            print(f"  shorebird-patch.yml 版本: {wf_ver}")
            if pub_ver != wf_ver:
                errors.append(f"版本不匹配！pubspec={pub_ver} vs workflow={wf_ver}")
            else:
                print("  ✅ 版本一致")
        else:
            warnings.append("shorebird-patch.yml 中未找到 release-version")
    else:
        warnings.append("未找到 shorebird-patch.yml")
else:
    errors.append("pubspec.yaml 中未找到 version")

# 3. 检查 git 状态
print("🔍 [3/3] Git 状态检查...")
result = subprocess.run(
    ["git", "status", "--short"],
    capture_output=True, text=True
)
modified_files = [l.strip() for l in result.stdout.strip().split('\n') if l.strip()]
if modified_files:
    print(f"  ⚠️ 有 {len(modified_files)} 个未提交的文件")
else:
    print("  ✅ 工作区干净")

# 4. 检查是否有残留的 lock 文件
lock_file = os.path.join(".git", "index.lock")
if os.path.exists(lock_file):
    errors.append(f"发现 git lock 文件: {lock_file}，请先删除")
else:
    print("  ✅ 无 git lock 残留")

# 输出结果
print("\n" + "="*50)
if errors:
    print("❌ 验证失败，不允许推送！")
    for e in errors:
        print(f"  ❌ {e}")
    for w in warnings:
        print(f"  ⚠️ {w}")
    sys.exit(1)
else:
    print("✅ 全部通过，可以安全推送！")
    for w in warnings:
        print(f"  ⚠️ {w}")
    sys.exit(0)
