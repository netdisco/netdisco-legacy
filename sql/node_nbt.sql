-- $Id$
-- node_nbt - Hold Netbios information for each node.

DROP TABLE node_nbt;

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
