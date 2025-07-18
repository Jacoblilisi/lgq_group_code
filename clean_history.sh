#!/bin/bash
# 使用git-filter-repo清理历史
git filter-repo \
  --path-glob '*.java' \
  --path-glob '*.pem' \
  --path-glob '*.key' \
  --blob-callback '
if b"LTAI4FzwedZ" in blob or b"BEGIN RSA PRIVATE KEY" in blob:
    print("Cleaning blob:", blob[0:100])
    blob = b"# REMOVED SENSITIVE DATA\n"
' --force
