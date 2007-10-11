-- $Id$

DROP TABLE device_power;

CREATE TABLE device_power (
    ip          inet,   -- ip of device
    module      integer,-- Module from PowerEthernet index
    power       integer,-- nominal power of the PSE expressed in Watts
    status      text,   -- The operational status
    PRIMARY KEY(ip,module)
);
