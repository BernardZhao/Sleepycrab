#!/bin/sh
# pf-sync.sh <port>: set transmission's peer-port to gluetun's forwarded port.
# Runs inside the gluetun container (shares its netns with transmission on :9091).
PORT="$1"
[ -n "$PORT" ] || exit 1
RPC="http://127.0.0.1:9091/transmission/rpc"
i=0
while [ $i -lt 20 ]; do
  SID=$(wget -q -S -O /dev/null "$RPC" 2>&1 | awk '/X-Transmission-Session-Id:/{print $2}' | tr -d '\r')
  if [ -n "$SID" ]; then
    RES=$(wget -qO- --header="X-Transmission-Session-Id: $SID" --post-data="{\"method\":\"session-set\",\"arguments\":{\"peer-port\":$PORT,\"peer-port-random-on-start\":false}}" "$RPC")
    case "$RES" in
      *'"result":"success"'*) echo "pf-sync: transmission peer-port set to $PORT"; exit 0 ;;
    esac
  fi
  i=$((i+1)); sleep 3
done
echo "pf-sync: FAILED to set peer-port $PORT" >&2
exit 1
