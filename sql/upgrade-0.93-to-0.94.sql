-- Netdisco
-- Database Schema Modifications
-- UPGRADE from 0.93 to 0.94
-- $Id$

ALTER TABLE device_port ADD COLUMN lastchange bigint;

ALTER TABLE log ADD COLUMN logfile text;

CREATE TABLE user_log (
    entry           serial,
    username        varchar(50),
    userip          inet,
    event           text,
    details         text,
    creation        TIMESTAMP DEFAULT now()
                      );

CREATE TABLE node_nbt (
    mac         macaddr PRIMARY KEY,
    ip          inet,
    nbname      text,
    domain      text,
    server      boolean,
    nbuser      text,
    active      boolean,
    time_first  timestamp default now(),
    time_last   timestamp default now()
);

-- Indexing speed ups.
CREATE INDEX idx_node_nbt_mac         ON node_nbt(mac);
CREATE INDEX idx_node_nbt_nbname      ON node_nbt(nbname);
CREATE INDEX idx_node_nbt_domain      ON node_nbt(domain);
CREATE INDEX idx_node_nbt_mac_active  ON node_nbt(mac,active);

-- Fix all the port names for Bay devices from 1 to 1.1
-- IF you have more than 48-port bay devices, make it so below.
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
UPDATE node set port='1.27' where port=27 and switch in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE node set port='1.28' where port=28 and switch in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE node set port='1.29' where port=29 and switch in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE node set port='1.30' where port=30 and switch in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE node set port='1.31' where port=31 and switch in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE node set port='1.32' where port=32 and switch in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE node set port='1.33' where port=33 and switch in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE node set port='1.34' where port=34 and switch in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE node set port='1.35' where port=35 and switch in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE node set port='1.36' where port=36 and switch in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE node set port='1.37' where port=37 and switch in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE node set port='1.38' where port=38 and switch in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE node set port='1.39' where port=39 and switch in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE node set port='1.40' where port=40 and switch in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE node set port='1.41' where port=41 and switch in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE node set port='1.42' where port=42 and switch in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE node set port='1.43' where port=43 and switch in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE node set port='1.44' where port=44 and switch in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE node set port='1.45' where port=45 and switch in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE node set port='1.46' where port=46 and switch in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE node set port='1.47' where port=47 and switch in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE node set port='1.48' where port=48 and switch in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE node set port='1.49' where port=49 and switch in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
-- device_port_log
UPDATE device_port_log set port='1.1' where port=1 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE device_port_log set port='1.3' where port=2 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
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
UPDATE device_port_log set port='1.27' where port=27 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE device_port_log set port='1.28' where port=28 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE device_port_log set port='1.29' where port=29 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE device_port_log set port='1.30' where port=30 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE device_port_log set port='1.31' where port=31 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE device_port_log set port='1.32' where port=32 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE device_port_log set port='1.33' where port=33 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE device_port_log set port='1.34' where port=34 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE device_port_log set port='1.35' where port=35 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE device_port_log set port='1.36' where port=36 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE device_port_log set port='1.37' where port=37 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE device_port_log set port='1.38' where port=38 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE device_port_log set port='1.39' where port=39 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE device_port_log set port='1.40' where port=40 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE device_port_log set port='1.41' where port=41 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE device_port_log set port='1.42' where port=42 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE device_port_log set port='1.43' where port=43 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE device_port_log set port='1.44' where port=44 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE device_port_log set port='1.45' where port=45 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE device_port_log set port='1.46' where port=46 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE device_port_log set port='1.47' where port=47 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE device_port_log set port='1.48' where port=48 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
UPDATE device_port_log set port='1.49' where port=49 and ip in (select distinct(d.ip) from device_port p, device d where d.ip=p.ip and d.vendor = 'bay');
