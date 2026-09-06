#!/bin/bash
mkdir -p /logs/verifier
if [ -f /app/hello.txt ] && [ "$(cat /app/hello.txt)" = "hello harbor" ]; then
  echo 1 > /logs/verifier/reward.txt
  echo "PASS"
else
  echo 0 > /logs/verifier/reward.txt
  echo "FAIL: /app/hello.txt missing or wrong"
  exit 1
fi
