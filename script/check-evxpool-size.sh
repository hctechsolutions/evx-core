#!/usr/bin/env sh
# Gate EIP-170 for EvxPool deployed/runtime bytecode (not creation, not Quoter).
# Fail if current > MAX_ALLOWED (EIP170 − MARGIN) or current > EIP170.
# remaining = MAX_ALLOWED − current (room until CI fail). Snapshot of exact size is not the gate.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
cd "$ROOT"

EIP170=24576
MARGIN=512
MAX_ALLOWED=$((EIP170 - MARGIN))

# Pool must stay independent of quote logic (quote lives in periphery Quoter).
if grep -E -q 'Quoter|quoteExact' src/contracts/EvxPool.sol; then
  echo "FAIL: EvxPool.sol must not reference Quoter / quoteExact" >&2
  exit 1
fi

hex=$(forge inspect EvxPool deployedBytecode | tr -d '[:space:]')
case "$hex" in
  0x*|0X*) hex=${hex#0x}; hex=${hex#0X} ;;
esac

if [ -z "$hex" ]; then
  echo "FAIL: empty EvxPool deployedBytecode" >&2
  exit 1
fi

len=${#hex}
if [ $((len % 2)) -ne 0 ]; then
  echo "FAIL: odd hex length for EvxPool deployedBytecode" >&2
  exit 1
fi

current=$((len / 2))
remaining=$((MAX_ALLOWED - current))

echo "current=${current}"
echo "MAX_ALLOWED=${MAX_ALLOWED}"
echo "EIP170=${EIP170}"
echo "remaining=${remaining}"

if [ "$current" -gt "$MAX_ALLOWED" ] || [ "$current" -gt "$EIP170" ]; then
  echo "FAIL: EvxPool deployedBytecode ${current} B exceeds gate (MAX_ALLOWED=${MAX_ALLOWED}, EIP170=${EIP170})" >&2
  exit 1
fi
