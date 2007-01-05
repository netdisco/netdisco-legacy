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
-- Add index on admin table
CREATE INDEX idx_admin_entered    ON admin(entered);

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
