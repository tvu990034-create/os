#!/bin/sh
# Observe Linux network-device state changes. This tool is diagnostic only:
# it never runs ifup/ifdown or rewrites netifd configuration.

STATE_DIR=/tmp/router-net/interface-states
DEFAULT_INTERVAL=10

log_msg() {
	logger -t router-net "$1"
}

valid_interval() {
	case "$1" in
		''|*[!0-9]*) return 1 ;;
	esac
	[ "$1" -ge 1 ] && [ "$1" -le 300 ]
}

get_interface_state() {
	iface_path=$1
	if [ ! -d "$iface_path" ]; then
		printf '%s' "missing"
		return
	fi
	state=unknown
	if [ -r "$iface_path/operstate" ]; then
		IFS= read -r state < "$iface_path/operstate" || state=unknown
	fi
	carrier=unknown
	if [ -r "$iface_path/carrier" ]; then
		IFS= read -r carrier < "$iface_path/carrier" || carrier=unknown
	fi
	printf '%s:%s' "$state" "$carrier"
}

check_interface() {
	iface_path=$1
	iface=${iface_path##*/}
	[ "$iface" = "lo" ] && return 0
	case "$iface" in *[!A-Za-z0-9_.:-]*) return 0 ;; esac

	mkdir -p "$STATE_DIR"
	current_state="$(get_interface_state "$iface_path")"
	state_file="$STATE_DIR/$iface"
	previous_state=
	[ -r "$state_file" ] && IFS= read -r previous_state < "$state_file"
	if [ "$current_state" != "$previous_state" ]; then
		printf '%s\n' "$current_state" > "$state_file"
		log_msg "device $iface state: ${previous_state:-unknown} -> $current_state"
	fi
}

monitor_once() {
	for iface_path in /sys/class/net/*; do
		[ -e "$iface_path" ] || continue
		check_interface "$iface_path"
	done
}

monitor_loop() {
	interval=$1
	log_msg "interface observer started (interval=${interval}s)"
	trap 'log_msg "interface observer stopped"; exit 0' INT TERM HUP
	while :; do
		monitor_once
		sleep "$interval"
	done
}

case "${1:-}" in
	--daemon)
		interval=${2:-$DEFAULT_INTERVAL}
		if ! valid_interval "$interval"; then
			echo "Invalid interval: $interval (expected 1..300 seconds)" >&2
			exit 2
		fi
		monitor_loop "$interval"
		;;
	--once|'')
		monitor_once
		;;
	*)
		echo "Usage: $0 [--once | --daemon [interval-seconds]]" >&2
		exit 2
		;;
esac
