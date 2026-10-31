#!/bin/sh
# Basic network health check for RouterOS

UCI_GET="uci -q get"
LOG_TAG="router-net-health"

log() {
	logger -t "$LOG_TAG" "$1"
}

check_service() {
	service=$1
	if [ -x "/etc/init.d/$service" ]; then
		/etc/init.d/$service status >/dev/null 2>&1
		if [ $? -eq 0 ]; then
			log "$service is running"
			return 0
		else
			log "$service is NOT running"
			return 1
		fi
	else
		log "$service init script not found"
		return 1
	fi
}

check_interface() {
	iface=$1
	if ip link show "$iface" >/dev/null 2>&1; then
		state=$(ip link show "$iface" 2>/dev/null | grep -oP '(?<=state )\w+' || echo "unknown")
		if [ "$state" = "UP" ] || [ "$state" = "UNKNOWN" ]; then
			log "Interface $iface is up (state: $state)"
			return 0
		else
			log "Interface $iface is down (state: $state)"
			return 1
		fi
	else
		log "Interface $iface does not exist"
		return 1
	fi
}

check_uci_config() {
	config=$1
	if uci -q show "$config" >/dev/null 2>&1; then
		log "UCI config $config is valid"
		return 0
	else
		log "UCI config $config is invalid or missing"
		return 1
	fi
}

main() {
	failed=0

	# Check critical network services
	if ! check_service firewall; then
		failed=1
	fi

	if ! check_service dnsmasq; then
		failed=1
	fi

	if ! check_service odhcpd; then
		failed=1
	fi

	if ! check_service uhttpd; then
		failed=1
	fi

	if ! check_service rpcd; then
		failed=1
	fi

	# Check network interfaces
	lan_device=$($UCI_GET network.lan.device 2>/dev/null || echo "br-lan")
	if ! check_interface "$lan_device"; then
		failed=1
	fi

	# Check UCI configurations
	if ! check_uci_config network; then
		failed=1
	fi

	if ! check_uci_config firewall; then
		failed=1
	fi

	if ! check_uci_config dhcp; then
		failed=1
	fi

	if [ $failed -eq 0 ]; then
		log "Network health check: PASSED"
		exit 0
	else
		log "Network health check: FAILED"
		exit 1
	fi
}

main "$@"
