-- $Id$

DROP TABLE node_monitor;

CREATE TABLE node_monitor (
    mac         macaddr,
    active      boolean,
    why         text,
    cc          text,
    date        TIMESTAMP DEFAULT now(),
    PRIMARY KEY(mac)
);
