-- $Id$
-- node_nbt - Hold Netbios information for each node.

DROP TABLE node_nbt;

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
