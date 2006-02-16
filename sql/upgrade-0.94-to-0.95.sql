-- Netdisco
-- Database Schema Modifications
-- UPGRADE from 0.94 to 0.95
-- $Id$

CREATE TABLE subnets (
    net cidr NOT NULL,
    creation timestamp default now(),
    last_discover timestamp default now(),
    PRIMARY KEY(net)
);

--
-- node_nbt could already exist, if you upgraded to 0.94, but if
-- you ran pg_all in 0.94, node_nbt wasn't created.  This
-- will report some harmless errors if it already exists.

CREATE TABLE node_nbt (
    mac         macaddr PRIMARY KEY,
    ip          inet,
    nbname      text,
    domain      text,
    server      boolean,
    nbuser      text,
    active      boolean,    -- do we need this still?
    time_first  timestamp default now(),
    time_last   timestamp default now()
);

-- Indexing speed ups.
CREATE INDEX idx_node_nbt_mac         ON node_nbt(mac);
CREATE INDEX idx_node_nbt_nbname      ON node_nbt(nbname);
CREATE INDEX idx_node_nbt_domain      ON node_nbt(domain);
CREATE INDEX idx_node_nbt_mac_active  ON node_nbt(mac,active);
