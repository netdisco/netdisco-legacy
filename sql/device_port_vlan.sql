-- $Id$

DROP TABLE device_port_vlan;

CREATE TABLE device_port_vlan (
    ip          inet,   -- ip of device
    port        text,   -- Unique identifier of Physical Port Name
    vlan        integer, -- VLAN ID
    native      boolean not null default false, -- native or trunked
    creation    TIMESTAMP DEFAULT now(),
    last_discover TIMESTAMP DEFAULT now(),
    PRIMARY KEY(ip,port,vlan)
);
