#!/bin/sh
# RouterOS connectivity test

UCI_GET="uci -q get"
LOG_TAG="router-connectivity"

log() {
	logger -t "$LOG_TAG" "$1"
}

test_dns() {
	dns_server=$1
	if [ -z "$dns_server" ]; then
		dns_server="8.8.8.8"
	fi
	
	if nslookup google.com "$dns_server" >/dev/null 2>&1; then
		log "DNS resolution successful via $dns_server"
		return 0
	else
		log "DNS resolution failed via $dns_server"
		return 1
	fi
}

test_internet() {
	if ping -c 3 -W 5 8.8.8.8 >/dev/null 2>&1; then
		log "Internet connectivity verified (8.8.8.8 reachable)"
		return 0
	else
		log "Internet connectivity failed (8.8.8.8 unreachable)"
		return 1
	fi
}

test_lan_gateway() {
	lan_ip=$($UCI_GET network.lan.ipaddr 2>/dev/null | cut -d'/' -f1)
	if [ -n "$lan_ip" ]; then
		if ping -c 2 -W 3 "$lan_ip" >/dev/null 2>&1; then
			log "LAN gateway reachable ($lan_ip)"
			return 0
		else
			log "LAN gateway unreachable ($lan_ip)"
			return 1
		fi
	else
		log "LAN IP not configured"
		return 1
	fi
}

test_dhcp_server() {
	if pgrep -f dnsmasq >/dev/null 2>&1; then
		log "DHCP server process running"
		return 0
	else
		log "DHCP server process not running"
		return 1
	fi
}

test_firewall() {
	if pgrep -f firewall4 >/dev/null 2>&1; then
		log "Firewall process running"
		return 0
	else
		log "Firewall process not running"
		return 1
	fi
}

main() {
	failed=0
	
	test_dhcp_server || failed=1
	test_firewall || failed=1
	test_lan_gateway || failed=1
	test_internet || failed=1
	test_dns || failed=1
	
	if [ $failed -eq 0 ]; then
		log "Connectivity test: PASSED"
		exit 0
	else
		log "Connectivity test: FAILED"
		exit 1
	fi
}

main "$@"
