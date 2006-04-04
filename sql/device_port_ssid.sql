-- $Id$

DROP TABLE device_port_ssid;

CREATE TABLE device_port_ssid (
    ip          inet,   -- ip of device
    port        text,   -- Unique identifier of Physical Port Name
    ssid        text,   -- An SSID that is valid on this port.
    broadcast   boolean,-- Is it broadcast?
    channel     integer -- 802.11 channel number
);

CREATE INDEX idx_device_port_ssid_ip_port ON device_port_ssid(ip,port);
