-- Database Schema Modifications for upgrading from 0.9x to 0.93
-- $Id$

ALTER TABLE device_port ADD COLUMN remote_type text;
ALTER TABLE device_port ADD COLUMN remote_id   text;
ALTER TABLE device_port ADD COLUMN vlan        text;
ALTER TABLE device_port ADD COLUMN vtpdomain   text; 
