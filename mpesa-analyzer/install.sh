#!/bin/bash
APP_DIR=$1
mkdir -p $APP_DIR/bin
echo 'echo "mpesa-analyzer v0.1 working! Usage: mpesa-analyzer statement.pdf"' > $APP_DIR/bin/mpesa-analyzer
chmod +x $APP_DIR/bin/mpesa-analyzer
echo "[✓] mpesa-analyzer installed"
