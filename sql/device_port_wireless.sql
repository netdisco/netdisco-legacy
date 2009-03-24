-- $Id$

DROP TABLE device_port_wireless;

CREATE TABLE device_port_wireless (
    ip          inet,   -- ip of device
    port        text,   -- Unique identifier of Physical Port Name
    channel     integer,-- 802.11 channel number
    power       integer -- transmit power in mw
);

CREATE INDEX idx_device_port_wireless_ip_port ON device_port_wireless(ip,port);
