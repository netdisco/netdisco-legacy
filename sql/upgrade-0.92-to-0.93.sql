-- Database Schema Modifications for upgrading from 0.9x to 0.93
-- $Id$

ALTER TABLE device_port
    ADD COLUMN remote_type text,
               vlan        text,
               vtpdomain   text; 
