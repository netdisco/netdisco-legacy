-- Netdisco
-- Database Schema Modifications
-- UPGRADE from 0.95 to 0.96
-- $Id$

--
-- Add snmp_class to device table
ALTER TABLE device ADD snmp_class text;

--
-- Add subnet to device_ip table
ALTER TABLE device_ip ADD subnet cidr;

--
-- Add indexes on admin table
CREATE INDEX idx_admin_entered ON admin(entered);
CREATE INDEX idx_admin_status  ON admin(status);
CREATE INDEX idx_admin_action  ON admin(action);

--
-- Create device_module table
CREATE TABLE device_module (
    ip            inet not null,
    index         integer,
    description   text,
    type          text,
    parent        integer,
    name          text,
    class         text,
    pos           integer,
    hw_ver        text,
    fw_ver        text,
    sw_ver        text,
    serial        text,
    model         text,
    fru           boolean,
    creation      TIMESTAMP DEFAULT now(),
    last_discover TIMESTAMP
    );

--
-- Earlier versions of device_module didn't have the index
ALTER TABLE device_module ADD PRIMARY KEY(ip,index);

-- Create process table - Queue to coordinate between processes in multi-process mode.
CREATE TABLE process (
    controller  integer not null, -- pid of controlling process
    device      inet not null,
    action      text not null,    -- arpnip, macsuck, nbtstat, discover
    status      text,    	  -- queued, running, skipped, done, error, timeout, nocdp, nosnmp
    count       integer,
    creation    TIMESTAMP DEFAULT now()
    );

--
-- Add ldap to users table
ALTER TABLE users ADD ldap boolean;
ALTER TABLE users ALTER ldap SET DEFAULT false;

--
-- Add pvid to device_port table
ALTER TABLE device_port ADD pvid integer;

--
-- Create device_port_vlan table
CREATE TABLE device_port_vlan (
    ip          inet,   -- ip of device
    port        text,   -- Unique identifier of Physical Port Name
    vlan        integer, -- VLAN ID
    native      boolean not null default false, -- native or trunked
    creation    TIMESTAMP DEFAULT now(),
    last_discover TIMESTAMP DEFAULT now(),
    PRIMARY KEY(ip,port,vlan)
);

--
-- Create device_vlan table
CREATE TABLE device_vlan (
    ip          inet,   -- ip of device
    vlan        integer, -- VLAN ID
    description text,   -- VLAN description
    creation    TIMESTAMP DEFAULT now(),
    last_discover TIMESTAMP DEFAULT now(),
    PRIMARY KEY(ip,vlan)
);

--
-- Create device_power table
CREATE TABLE device_power (
    ip          inet,   -- ip of device
    module      integer,-- Module from PowerEthernet index
    power       integer,-- nominal power of the PSE expressed in Watts
    status      text,   -- The operational status
    PRIMARY KEY(ip,module)
);

--
-- Create device_port_power table
CREATE TABLE device_port_power (
    ip          inet,   -- ip of device
    port        text,   -- Unique identifier of Physical Port Name
    module      integer,-- Module from PowerEthernet index
    admin       text,   -- Admin power status
    status      text,   -- Detected power status
    class       text,   -- Detected class
    PRIMARY KEY(port,ip)
);