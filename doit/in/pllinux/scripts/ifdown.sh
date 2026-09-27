#!/app/busybox/current/bin/sh
# Script run from ifdown - should clean settings on network device
if [ ! -d "/log" ]; then
  echo "Cannot be run from host"
  return
fi
echo running on $IFACE
killall udhcpc
ip -4 addr flush dev $IFACE
ip link set dev $IFACE down
