-- $Id$

DROP TABLE node_wireless;

CREATE TABLE node_wireless (
    mac         macaddr,
    ssid        text default '',
    uptime      integer,
    maxrate     integer, -- can be 0.5 but we ignore that for now
    txrate      integer, -- can be 0.5 but we ignore that for now
    sigstrength integer, -- signal strength (-db)
    sigqual     integer, -- signal quality
    rxpkt       integer, -- received packets
    txpkt       integer, -- transmitted packets
    rxbyte      bigint,  -- received bytes
    txbyte      bigint,  -- transmitted bytes
    time_last   timestamp default now(),
    PRIMARY KEY(mac,ssid)
);

