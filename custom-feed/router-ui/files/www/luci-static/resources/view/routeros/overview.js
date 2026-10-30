'use strict';
'require view';
'require rpc';

var callSystemBoard = rpc.declare({
	object: 'system',
	method: 'board'
});

var callSystemInfo = rpc.declare({
	object: 'system',
	method: 'info'
});

var callNetworkDump = rpc.declare({
	object: 'network.interface',
	method: 'dump'
});

function safeValue(value) {
	return (value !== undefined && value !== null && value !== '') ? value : _('Unavailable');
}

function formatUptime(seconds) {
	if (typeof seconds !== 'number' || !isFinite(seconds) || seconds < 0)
		return _('Unavailable');

	var days = Math.floor(seconds / 86400);
	var hours = Math.floor((seconds % 86400) / 3600);
	var minutes = Math.floor((seconds % 3600) / 60);

	return (days ? days + _('d ') : '') + hours + _('h ') + minutes + _('m');
}

function formatLoad(load) {
	if (!Array.isArray(load) || load.length < 3)
		return _('Unavailable');

	return load.map(function(value) {
		return (Number(value) / 65535).toFixed(2);
	}).join(', ');
}

function makeInfoTable(fields) {
	var table = E('table', { 'class': 'table' });

	fields.forEach(function(field) {
		table.appendChild(E('tr', { 'class': 'tr' }, [
			E('td', { 'class': 'td left', 'width': '33%' }, [ field[0] ]),
			E('td', { 'class': 'td left' }, [ String(safeValue(field[1])) ])
		]));
	});

	return table;
}

function makeInterfaceTable(items) {
	var table = E('table', { 'class': 'table' }, [
		E('tr', { 'class': 'tr table-titles' }, [
			E('th', { 'class': 'th' }, [ _('Interface') ]),
			E('th', { 'class': 'th' }, [ _('Device') ]),
			E('th', { 'class': 'th' }, [ _('Protocol') ]),
			E('th', { 'class': 'th' }, [ _('State') ]),
			E('th', { 'class': 'th' }, [ _('IPv4 Address') ])
		])
	]);

	if (!Array.isArray(items) || items.length === 0) {
		table.appendChild(E('tr', { 'class': 'tr' }, [
			E('td', { 'class': 'td' , 'colspan': '5' }, [ _('No network interfaces reported') ])
		]));
		return table;
	}

	items.forEach(function(item) {
		var addresses = Array.isArray(item['ipv4-address']) ? item['ipv4-address'] : [];
		var addressText = addresses.map(function(entry) {
			return entry.address + '/' + entry.mask;
		}).join(', ');

		table.appendChild(E('tr', { 'class': 'tr' }, [
			E('td', { 'class': 'td' }, [ safeValue(item.interface) ]),
			E('td', { 'class': 'td' }, [ safeValue(item.device) ]),
			E('td', { 'class': 'td' }, [ safeValue(item.proto) ]),
			E('td', { 'class': 'td' }, [ item.up ? _('Up') : _('Down') ]),
			E('td', { 'class': 'td' }, [ safeValue(addressText) ])
		]));
	});

	return table;
}

return view.extend({
	load: function() {
		return Promise.all([
			L.resolveDefault(callSystemBoard(), {}),
			L.resolveDefault(callSystemInfo(), {}),
			L.resolveDefault(callNetworkDump(), {})
		]);
	},

	render: function(data) {
		var board = data[0] || {};
		var system = data[1] || {};
		var network = data[2] || {};

		var release = board.release || {};
		var load = formatLoad(system.load);

		var systemFields = [
			[ _('Hostname'), board.hostname ],
			[ _('Model'), board.model ],
			[ _('Architecture'), board.system ],
			[ _('Target'), release.target ],
			[ _('Firmware'), release.description ],
			[ _('Kernel'), board.kernel ],
			[ _('Uptime'), formatUptime(system.uptime) ],
			[ _('Load Average'), load ]
		];

		return E('div', { 'class': 'cbi-map' }, [
			E('h2', {}, [ _('RouterOS Overview') ]),
			E('p', { 'class': 'cbi-map-descr' }, [
				_('Read-only system and interface status for this RouterOS device.')
			]),
			E('div', { 'class': 'cbi-section' }, [
				E('h3', {}, [ _('System Information') ]),
				makeInfoTable(systemFields)
			]),
			E('div', { 'class': 'cbi-section' }, [
				E('h3', {}, [ _('Network Interfaces') ]),
				makeInterfaceTable(network.interface)
			])
		]);
	}
});
