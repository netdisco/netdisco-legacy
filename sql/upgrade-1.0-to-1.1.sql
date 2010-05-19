-- Netdisco
-- Database Schema Modifications
-- UPGRADE from 1.0 to 1.1
-- $Id$

--
-- Add index to node_ip table
CREATE INDEX idx_node_ip_ip_active   ON node_ip(ip,active);
