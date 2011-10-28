-- Netdisco
-- Database Schema Modifications
-- UPGRADE from 1.1 to 1.2

-- Add "vlantype" column to device_port_vlan table
ALTER TABLE device_port_vlan ADD vlantype text;
