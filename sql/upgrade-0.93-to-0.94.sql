-- Netdisco
-- Database Schema Modifications
-- UPGRADE from 0.93 to 0.94
-- $Id$

ALTER TABLE device_port ADD COLUMN lastchange bigint;

CREATE TABLE user_log (
    entry           serial,
    username        varchar(50),
    userip          inet,
    event           text,
    details         text,
    creation        TIMESTAMP DEFAULT now()
                      );

CREATE TABLE node_nbt (
    ip          inet,
    mac         macaddr,
    nbname      text,
    domain      text,
    server      boolean,
    nbuser      text,
    active      boolean,
    time_first  timestamp default now(),
    time_last   timestamp default now(),
    PRIMARY KEY(ip,mac)
);

-- Indexing speed ups.
CREATE INDEX idx_node_nbt_mac         ON node_nbt(mac);
CREATE INDEX idx_node_nbt_nbname      ON node_nbt(nbname);
CREATE INDEX idx_node_nbt_domain      ON node_nbt(domain);
CREATE INDEX idx_node_nbt_mac_active  ON node_nbt(mac,active);

-- Fix all the port names for Bay devices from 1 to 1.1
-- IF you have more than 24-port bay devices, make it so below.
UPDATE node set port='1.1' where port=1 and switch in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE node set port='1.2' where port=2 and switch in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE node set port='1.3' where port=3 and switch in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE node set port='1.4' where port=4 and switch in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE node set port='1.5' where port=5 and switch in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE node set port='1.6' where port=6 and switch in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE node set port='1.7' where port=7 and switch in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE node set port='1.8' where port=8 and switch in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE node set port='1.9' where port=9 and switch in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE node set port='1.10' where port=10 and switch in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE node set port='1.11' where port=11 and switch in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE node set port='1.12' where port=12 and switch in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE node set port='1.13' where port=13 and switch in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE node set port='1.14' where port=14 and switch in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE node set port='1.15' where port=15 and switch in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE node set port='1.16' where port=16 and switch in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE node set port='1.17' where port=17 and switch in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE node set port='1.18' where port=18 and switch in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE node set port='1.19' where port=19 and switch in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE node set port='1.20' where port=20 and switch in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE node set port='1.21' where port=21 and switch in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE node set port='1.22' where port=22 and switch in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE node set port='1.23' where port=23 and switch in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE node set port='1.24' where port=24 and switch in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE node set port='1.25' where port=25 and switch in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE node set port='1.26' where port=26 and switch in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
-- device_port_log
UPDATE device_port_log set port='1.1' where port=1 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE device_port_log set port='1.2' where port=2 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE device_port_log set port='1.3' where port=3 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE device_port_log set port='1.4' where port=4 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE device_port_log set port='1.5' where port=5 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE device_port_log set port='1.6' where port=6 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE device_port_log set port='1.7' where port=7 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE device_port_log set port='1.8' where port=8 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE device_port_log set port='1.9' where port=9 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE device_port_log set port='1.10' where port=10 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE device_port_log set port='1.11' where port=11 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE device_port_log set port='1.12' where port=12 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE device_port_log set port='1.13' where port=13 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE device_port_log set port='1.14' where port=14 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE device_port_log set port='1.15' where port=15 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE device_port_log set port='1.16' where port=16 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE device_port_log set port='1.17' where port=17 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE device_port_log set port='1.18' where port=18 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE device_port_log set port='1.19' where port=19 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE device_port_log set port='1.20' where port=20 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE device_port_log set port='1.21' where port=21 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE device_port_log set port='1.22' where port=22 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE device_port_log set port='1.23' where port=23 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE device_port_log set port='1.24' where port=24 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE device_port_log set port='1.25' where port=25 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE device_port_log set port='1.26' where port=26 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
