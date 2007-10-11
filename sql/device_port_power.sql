-- $Id$

DROP TABLE device_port_power;

CREATE TABLE device_port_power (
    ip          inet,   -- ip of device
    port        text,   -- Unique identifier of Physical Port Name
    module      integer,-- Module from PowerEthernet index
    admin       text,   -- Admin power status
    status      text,   -- Detected power status
    class       text,   -- Detected class
    PRIMARY KEY(port,ip)
);
