#!/bin/sh
# Router OS Interface Monitor
# Monitors network interface state and triggers recovery actions

INTERFACE_STATE_FILE="/tmp/router-net/interface-states"
RECOVERY_DELAY=5

log_msg() {
	logger -t router-net "$1"
}

save_interface_state() {
	local iface=$1
	local state=$2
	mkdir -p $(dirname "$INTERFACE_STATE_FILE")
	echo "$state" > "$INTERFACE_STATE_FILE/$iface"
}

get_interface_state() {
	local iface=$1
	if [ -f "$INTERFACE_STATE_FILE/$iface" ]; then
		cat "$INTERFACE_STATE_FILE/$iface"
	else
		echo "unknown"
	fi
}

check_interface() {
	local iface=$1
	local current_state
	
	# Get current operational state
	if [ -d "/sys/class/net/$iface" ]; then
		current_state="up"
	else
		current_state="down"
	fi
	
	local prev_state=$(get_interface_state "$iface")
	
	if [ "$current_state" != "$prev_state" ]; then
		log_msg "Interface $iface state changed: $prev_state -> $current_state"
		save_interface_state "$iface" "$current_state"
		
		# If interface came up, trigger network reconfiguration
		if [ "$current_state" = "up" ]; then
			log_msg "Interface $iface came up, triggering ifup"
			/sbin/ifup "$iface" 2>/dev/null || true
		fi
	fi
}

monitor_all_interfaces() {
	for iface in /sys/class/net/*; do
		ifname=$(basename "$iface")
		# Skip loopback
		[ "$ifname" = "lo" ] && continue
		check_interface "$ifname"
	done
}

# Main monitoring loop
monitor_loop() {
	log_msg "Interface monitor started"
	
	while true; do
		monitor_all_interfaces
		sleep 10
	done
}

# Run in background if called directly
if [ "$1" = "--daemon" ]; then
	monitor_loop
else
	# Single check mode
	monitor_all_interfaces
fi
