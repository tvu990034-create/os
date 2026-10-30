#!/bin/sh
# Router OS Interface Monitor
# Observe Linux operational state without overriding netifd's interface policy.

SYS_CLASS_NET="${SYS_CLASS_NET:-/sys/class/net}"
STATE_DIR="${STATE_DIR:-/tmp/router-net/interface-states}"
INTERVAL="${2:-${INTERVAL:-10}}"

case "$INTERVAL" in
	''|*[!0-9]*) INTERVAL=10 ;;
esac
[ "$INTERVAL" -ge 1 ] 2>/dev/null || INTERVAL=10

log_msg() {
	logger -t router-net "$1" 2>/dev/null || true
}

read_interface_state() {
	iface="$1"
	iface_dir="$SYS_CLASS_NET/$iface"

	if [ ! -d "$iface_dir" ]; then
		printf '%s\n' "down"
		return 0
	fi

	if [ -r "$iface_dir/operstate" ]; then
		state="$(cat "$iface_dir/operstate" 2>/dev/null || true)"
		[ -n "$state" ] || state="unknown"
	else
		state="unknown"
	fi

	printf '%s\n' "$state"
}

save_interface_state() {
	iface="$1"
	state="$2"

	if ! mkdir -p "$STATE_DIR"; then
		log_msg "Unable to create interface state directory: $STATE_DIR"
		return 1
	fi

	printf '%s\n' "$state" > "$STATE_DIR/$iface"
}

get_interface_state() {
	iface="$1"
	state_file="$STATE_DIR/$iface"

	if [ -r "$state_file" ]; then
		cat "$state_file"
	else
		printf '%s\n' "unknown"
	fi
}

check_interface() {
	iface="$1"
	current_state="$(read_interface_state "$iface")"
	previous_state="$(get_interface_state "$iface")"

	if [ "$current_state" != "$previous_state" ]; then
		log_msg "Interface $iface operational state changed: $previous_state -> $current_state"
		save_interface_state "$iface" "$current_state"
	fi
}

monitor_all_interfaces() {
	if [ ! -d "$SYS_CLASS_NET" ]; then
		log_msg "Network sysfs directory is unavailable: $SYS_CLASS_NET"
		return 1
	fi

	for iface_path in "$SYS_CLASS_NET"/*; do
		[ -e "$iface_path" ] || continue
		iface="${iface_path##*/}"
		[ "$iface" = "lo" ] && continue
		check_interface "$iface"
	done
}

monitor_loop() {
	log_msg "Interface monitor started (interval: ${INTERVAL}s)"
	while :; do
		monitor_all_interfaces
		sleep "$INTERVAL"
	done
}

case "${1:-}" in
	--daemon)
		monitor_loop
		;;
	""|--once)
		monitor_all_interfaces
		;;
	*)
		echo "Usage: $0 [--once | --daemon [interval-seconds]]" >&2
		exit 2
		;;
esac
