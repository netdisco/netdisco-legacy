-- $Id$

DROP TABLE node_ip;

CREATE TABLE node_ip (
    mac         macaddr,
    ip          inet,
    active      boolean,
    time_first  timestamp default now(),
    time_last   timestamp default now(),
    PRIMARY KEY(mac,ip)
);

-- Indexing speed ups.
CREATE INDEX idx_node_ip_ip          ON node_ip(ip);
CREATE INDEX idx_node_ip_mac         ON node_ip(mac);
CREATE INDEX idx_node_ip_mac_active  ON node_ip(mac,active);
