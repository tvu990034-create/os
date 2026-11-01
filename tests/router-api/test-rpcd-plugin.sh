#!/bin/sh
# Exercise rpcd protocol, ACL scope, network changes and input validation.

set -eu
ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
PLUGIN="$ROOT_DIR/custom-feed/router-api/files/router-api"
ACL="$ROOT_DIR/custom-feed/router-api/files/acl.d/router-api-acl.json"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT HUP INT TERM

mkdir -p "$TMP_DIR/bin" "$TMP_DIR/usr/libexec/router-core" \
	"$TMP_DIR/sys-class-net/br-lan/brif" "$TMP_DIR/sys-class-net/eth0" \
	"$TMP_DIR/sys-class-net/eth1"
: > "$TMP_DIR/sys-class-net/br-lan/brif/eth0"

python3 - "$ACL" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as stream:
    acl = json.load(stream)

read_methods = set(acl["router-api-read"]["read"]["ubus"]["router-api"])
write_methods = set(acl["router-api-write"]["write"]["ubus"]["router-api"])
assert read_methods == {
    "get_system_info", "get_network_status", "get_monitoring",
    "get_device_info", "list_backups",
}
assert write_methods == {
    "backup_config", "set_lan_config", "set_wan_config", "set_dhcp_config",
}
for role in ("router-api-read", "router-api-write"):
    permissions = acl[role]
    assert "uci" not in permissions.get("read", {})
    assert "uci" not in permissions.get("write", {})
    assert "file" not in permissions.get("read", {})
    assert "file" not in permissions.get("write", {})
assert not acl["unauthenticated"].get("read")
assert not acl["unauthenticated"].get("write")
PY

cat > "$TMP_DIR/jshn.sh" <<'JSHN'
json_load() {
	_JSHN_INPUT=$1
	printf '%s' "$_JSHN_INPUT" | python3 -c 'import json,sys; assert isinstance(json.load(sys.stdin), dict)' >/dev/null
}
json_get_var() {
	_JSHN_VALUE=$(printf '%s' "$_JSHN_INPUT" | python3 -c 'import json,sys; print(json.load(sys.stdin).get(sys.argv[1], ""))' "$2")
	case "$1" in
		IPADDR) IPADDR=$_JSHN_VALUE ;;
		NETMASK) NETMASK=$_JSHN_VALUE ;;
		PROTO) PROTO=$_JSHN_VALUE ;;
		DEVICE) DEVICE=$_JSHN_VALUE ;;
		REQUEST_DEVICE) REQUEST_DEVICE=$_JSHN_VALUE ;;
		GATEWAY) GATEWAY=$_JSHN_VALUE ;;
		START) START=$_JSHN_VALUE ;;
		LIMIT) LIMIT=$_JSHN_VALUE ;;
		LEASE) LEASE=$_JSHN_VALUE ;;
		*) return 1 ;;
	esac
}
json_init() { _JSON_RESPONSE='{}'; }
json_add_string() {
	_JSON_RESPONSE=$(JSON_KEY="$1" JSON_VALUE="$2" JSON_RESPONSE="$_JSON_RESPONSE" python3 -c 'import json,os; d=json.loads(os.environ["JSON_RESPONSE"]); d[os.environ["JSON_KEY"]]=os.environ["JSON_VALUE"]; print(json.dumps(d,separators=(",",":")))')
}
json_dump() { printf '%s\n' "$_JSON_RESPONSE"; }
JSHN

cat > "$TMP_DIR/bin/uci" <<'UCI'
#!/bin/sh
if [ "$1" = "-q" ]; then shift; fi
if [ "$1" = "get" ]; then
	case "$2" in
		network.lan) echo interface; exit 0 ;;
		network.lan.device) echo br-lan; exit 0 ;;
		network.wan) echo interface; exit 0 ;;
		network.wan.device)
			[ -n "$WAN_DEVICE" ] || exit 1
			echo "$WAN_DEVICE"
			exit 0
			;;
	esac
fi
printf '%s\n' "$*" >> "$UCI_LOG"
UCI
cat > "$TMP_DIR/bin/network-init" <<'INIT'
#!/bin/sh
printf 'network %s\n' "$*" >> "$INIT_LOG"
INIT
cat > "$TMP_DIR/bin/dnsmasq-init" <<'INIT'
#!/bin/sh
printf 'dnsmasq %s\n' "$*" >> "$INIT_LOG"
INIT
cat > "$TMP_DIR/usr/libexec/router-core/router-status" <<'REPORT'
#!/bin/sh
echo router-status-ok
REPORT
chmod +x "$TMP_DIR/bin/uci" "$TMP_DIR/bin/network-init" "$TMP_DIR/bin/dnsmasq-init" "$TMP_DIR/usr/libexec/router-core/router-status"
export UCI_LOG="$TMP_DIR/uci.log" INIT_LOG="$TMP_DIR/init.log" WAN_DEVICE=
: > "$UCI_LOG"
: > "$INIT_LOG"

"$PLUGIN" list | python3 -c 'import json,sys; d=json.load(sys.stdin); assert "get_system_info" in d and "set_lan_config" in d and "set_wan_config" in d and "device" in d["set_wan_config"]'

run_call() {
	method=$1
	body=$2
	printf '%s\n' "$body" | ROUTER_API_JSHN_LIB="$TMP_DIR/jshn.sh" \
		ROUTER_API_LIBEXEC_ROOT="$TMP_DIR/usr/libexec" \
		ROUTER_API_NETWORK_INIT="$TMP_DIR/bin/network-init" \
		ROUTER_API_DNSMASQ_INIT="$TMP_DIR/bin/dnsmasq-init" \
		ROUTER_API_SYS_CLASS_NET="$TMP_DIR/sys-class-net" \
		PATH="$TMP_DIR/bin:$PATH" "$PLUGIN" call "$method"
}

REPORT=$(run_call get_system_info '{}')
printf '%s\n' "$REPORT" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d["status"]=="ok" and "router-status-ok" in d["output"]'

LAN=$(run_call set_lan_config '{"ipaddr":"192.168.50.1","netmask":"255.255.255.0"}')
printf '%s\n' "$LAN" | python3 -c 'import json,sys; assert json.load(sys.stdin)["status"]=="ok"'
grep -Fq 'set network.lan.ipaddr=192.168.50.1' "$UCI_LOG"
grep -Fq 'network reload' "$INIT_LOG"

BEFORE=$(wc -l < "$UCI_LOG")
if run_call set_lan_config '{"ipaddr":"192.168.50.1;reboot","netmask":"255.255.255.0"}' >/dev/null 2>&1; then
	echo "FAIL: invalid LAN address was accepted" >&2
	exit 1
fi
[ "$BEFORE" -eq "$(wc -l < "$UCI_LOG")" ] || {
	echo "FAIL: invalid LAN input reached UCI" >&2
	exit 1
}

if run_call set_wan_config '{"proto":"dhcp"}' >/dev/null 2>&1; then
	echo "FAIL: WAN without a selected device was accepted" >&2
	exit 1
fi
if run_call set_wan_config '{"proto":"dhcp","device":"eth0"}' >/dev/null 2>&1; then
	echo "FAIL: LAN bridge member was accepted as WAN" >&2
	exit 1
fi
if run_call set_wan_config '{"proto":"dhcp","device":"eth1;reboot"}' >/dev/null 2>&1; then
	echo "FAIL: invalid WAN device name was accepted" >&2
	exit 1
fi
if run_call set_wan_config '{"proto":"static","device":"eth1","ipaddr":"192.0.2.10","netmask":"255.255.255.0"}' >/dev/null 2>&1; then
	echo "FAIL: static WAN without a gateway was accepted" >&2
	exit 1
fi

WAN=$(run_call set_wan_config '{"proto":"static","device":"eth1","ipaddr":"192.0.2.10","netmask":"255.255.255.0","gateway":"192.0.2.1"}')
printf '%s\n' "$WAN" | python3 -c 'import json,sys; assert json.load(sys.stdin)["status"]=="ok"'
grep -Fq 'set network.wan.device=eth1' "$UCI_LOG"
grep -Fq 'set network.wan.gateway=192.0.2.1' "$UCI_LOG"

DHCP=$(run_call set_wan_config '{"proto":"dhcp","device":"eth1"}')
printf '%s\n' "$DHCP" | python3 -c 'import json,sys; assert json.load(sys.stdin)["status"]=="ok"'

DHCP_LAN=$(run_call set_dhcp_config '{"start":"100","limit":"150","leasetime":"12h"}')
printf '%s\n' "$DHCP_LAN" | python3 -c 'import json,sys; assert json.load(sys.stdin)["status"]=="ok"'
grep -Fq 'set dhcp.lan.leasetime=12h' "$UCI_LOG"
grep -Fq 'dnsmasq reload' "$INIT_LOG"

if run_call set_dhcp_config '{"start":"250","limit":"20","leasetime":"12h"}' >/dev/null 2>&1; then
	echo "FAIL: invalid DHCP range was accepted" >&2
	exit 1
fi
if run_call set_dhcp_config '{"start":"100","limit":"150","leasetime":"99d"}' >/dev/null 2>&1; then
	echo "FAIL: excessive DHCP lease was accepted" >&2
	exit 1
fi
echo "RouterOS rpcd plugin protocol, ACL, WAN device and UCI validation tests passed."
