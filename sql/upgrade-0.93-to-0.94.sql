-- Netdisco
-- Database Schema Modifications
-- UPGRADE from 0.93 to 0.94

ALTER TABLE device_port ADD COLUMN lastchange bigint;
