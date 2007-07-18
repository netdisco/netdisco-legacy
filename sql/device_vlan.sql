-- $Id$

DROP TABLE device_vlan;

CREATE TABLE device_vlan (
    ip          inet,   -- ip of device
    vlan        integer, -- VLAN ID
    description text,   -- VLAN description
    creation    TIMESTAMP DEFAULT now(),
    last_discover TIMESTAMP DEFAULT now(),
    PRIMARY KEY(ip,vlan)
);
