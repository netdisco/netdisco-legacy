-- $Id$

DROP TABLE node;

CREATE TABLE node (
    mac         macaddr,
    switch      inet,
    port        text,
    active      boolean,
    oui         varchar(8),  -- fe:9a:57
    time_first  timestamp default now(),
    time_recent timestamp default now(),
    time_last   timestamp default now(),
    PRIMARY KEY(mac,switch,port) 
);

-- Indexes speed things up a LOT
CREATE INDEX idx_node_switch_port_active ON node(switch,port,active);
CREATE INDEX idx_node_switch_port ON node(switch,port);
CREATE INDEX idx_node_switch      ON node(switch);
CREATE INDEX idx_node_mac         ON node(mac);
CREATE INDEX idx_node_mac_active  ON node(mac,active);
-- CREATE INDEX idx_node_oui         ON node(oui);
