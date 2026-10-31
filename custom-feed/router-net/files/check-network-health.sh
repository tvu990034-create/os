#!/bin/sh
# Network health check for RouterOS - respects board configuration

UCI_GET="uci -q get"
LOG_TAG="router-net-health"
FAILED_CHECKS=0

log() {
	logger -t "$LOG_TAG" "$1"
}

check_service() {
	service=$1
	optional=${2:-0}
	
	if [ -x "/etc/init.d/$service" ]; then
		/etc/init.d/$service status >/dev/null 2>&1
		status=$?
		if [ $status -eq 0 ]; then
			log "$service is running"
			return 0
		else
			if [ "$optional" = "1" ]; then
				log "$service is not running (optional)"
				return 0
			else
				log "$service is NOT running (required)"
				FAILED_CHECKS=$((FAILED_CHECKS + 1))
				return 1
			fi
		fi
	else
		if [ "$optional" = "1" ]; then
			log "$service not installed (optional)"
			return 0
		else
			log "$service init script not found (required)"
			FAILED_CHECKS=$((FAILED_CHECKS + 1))
			return 1
		fi
	fi
}

check_interface() {
	iface=$1
	required=${2:-1}
	
	if [ -z "$iface" ] || [ "$iface" = "" ]; then
		if [ "$required" = "1" ]; then
			log "interface name is empty (required)"
			FAILED_CHECKS=$((FAILED_CHECKS + 1))
		else
			log "interface name is empty (optional)"
		fi
		return 1
	fi
	
	if ip link show "$iface" >/dev/null 2>&1; then
		state=$(ip link show "$iface" 2>/dev/null | sed -n 's/.*state \([A-Z]*\).*/\1/p' || echo "unknown")
		if [ "$state" = "UP" ] || [ "$state" = "UNKNOWN" ]; then
			log "Interface $iface is up (state: $state)"
			return 0
		else
			if [ "$required" = "1" ]; then
				log "Interface $iface is down (state: $state)"
				FAILED_CHECKS=$((FAILED_CHECKS + 1))
			else
				log "Interface $iface is down (state: $state, optional)"
			fi
			return 1
		fi
	else
		if [ "$required" = "1" ]; then
			log "Interface $iface does not exist (required)"
			FAILED_CHECKS=$((FAILED_CHECKS + 1))
		else
			log "Interface $iface does not exist (optional)"
		fi
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
		FAILED_CHECKS=$((FAILED_CHECKS + 1))
		return 1
	fi
}

check_routing() {
	# Check if default route exists
	if ip route show default >/dev/null 2>&1; then
		log "default route exists"
		return 0
	else
		log "no default route (may be expected on single-NIC or LAN-only setup)"
		return 0
	fi
}

check_dhcp() {
	# Check if dnsmasq is actually listening
	if pgrep -f dnsmasq >/dev/null 2>&1; then
		log "dnsmasq process is running"
		return 0
	else
		log "dnsmasq process not found"
		FAILED_CHECKS=$((FAILED_CHECKS + 1))
		return 1
	fi
}

main() {
	# Check critical network services (required)
	check_service firewall 0
	check_service dnsmasq 0
	check_service rpcd 0
	
	# Check optional services (may not be installed on all boards)
	check_service odhcpd 1
	check_service uhttpd 1
	check_service dropbear 1

	# Check LAN interface (required)
	lan_device=$($UCI_GET network.lan.device 2>/dev/null || echo "")
	if [ -z "$lan_device" ]; then
		# Try to infer from lan_bridge if it exists
		lan_bridge=$($UCI_GET network.lan_bridge.name 2>/dev/null || echo "")
		if [ -n "$lan_bridge" ]; then
			lan_device="$lan_bridge"
		else
			lan_device="br-lan"
		fi
	fi
	check_interface "$lan_device" 1

	# Check WAN interface if configured (optional)
	if $UCI_GET network.wan >/dev/null 2>&1; then
		wan_device=$($UCI_GET network.wan.device 2>/dev/null || echo "")
		if [ -n "$wan_device" ]; then
			check_interface "$wan_device" 0
		fi
	fi

	# Check UCI configurations (required)
	check_uci_config network
	check_uci_config firewall
	check_uci_config dhcp

	# Check routing
	check_routing

	# Check DHCP process
	check_dhcp

	if [ $FAILED_CHECKS -eq 0 ]; then
		log "Network health check: PASSED"
		exit 0
	else
		log "Network health check: FAILED ($FAILED_CHECKS failed check(s))"
		exit 1
	fi
}

main "$@"
