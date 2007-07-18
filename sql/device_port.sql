-- $Id$

DROP TABLE device_port;

CREATE TABLE device_port (
    ip          inet,   -- ip of device
    port        text,   -- Unique identifier of Physical Port Name
    creation    TIMESTAMP DEFAULT now(),
    descr       text,   -- Description of Port 
    up          text,   -- Current Link Status
    up_admin    text,   -- Admin Link Status
    type        text,   -- Description of Port Media Type
    duplex      text,   -- Current Duplex Setting
    duplex_admin text,  -- Admin Duplex Setting
    speed       text, 
    name        text,   -- Human Set name
    mac         macaddr,-- MAC of the switch port
    mtu         integer,
    stp         text,   -- Spanning Tree Protocol Status
    remote_ip   inet,   -- Neighboring device connected to
    remote_port text,   -- Neighboring port connected to
    remote_type text,   -- Type of device connected to
    remote_id   text,   -- remote ID string of neighbor
    vlan        text,   -- VLAN port connected to
    pvid        integer,-- PVID for incoming untagged packets
    lastchange  bigint, -- Last time the port went up or down
    PRIMARY KEY(port,ip) 
);

CREATE INDEX idx_device_port_ip ON device_port(ip);
CREATE INDEX idx_device_port_remote_ip ON device_port(remote_ip);
-- For the duplex mismatch finder :
CREATE INDEX idx_device_port_ip_port_duplex ON device_port(ip,port,duplex);
CREATE INDEX idx_device_port_ip_up_admin ON device_port(ip,up_admin);
CREATE INDEX idx_device_port_mac ON device_port(mac);
