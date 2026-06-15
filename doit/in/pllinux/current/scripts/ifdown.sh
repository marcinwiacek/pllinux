#!/app/busybox/current/bin/sh
# Script run from ifdown - should clean settings on network device
echo running on $IFACE
killall udhcpc
ip -4 addr flush dev $IFACE
ip link set dev $IFACE down
