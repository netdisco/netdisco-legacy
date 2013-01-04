-- Netdisco
-- Database Schema Modifications
-- UPGRADE from 1.1 to 1.2

-- Add "vlantype" column to device_port_vlan table
ALTER TABLE device_port_vlan ADD vlantype text;

-- Add "topology" table to augment manual topo file
CREATE TABLE topology (
    dev1   inet not null,
    port1  text not null,
    dev2   inet not null,
    port2  text not null
);

-- Add "bssid" column to device_port_ssid table
ALTER TABLE device_port_ssid ADD bssid macaddr;

-- Add "vlan" column to node table
ALTER TABLE node ADD vlan text default '0';

alter table node drop constraint node_pkey;
alter table node add primary key (mac, switch, port, vlan);

-- Add "ssid" column to node_wireless table
ALTER TABLE node_wireless ADD ssid text default '';

alter table node_wireless drop constraint node_wireless_pkey;
alter table node_wireless add primary key (mac, ssid);
