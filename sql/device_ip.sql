-- $Id$

DROP TABLE device_ip;

CREATE TABLE device_ip (
    ip          inet,
    alias       inet,
    subnet      cidr,
    port        text,
    dns         text,
    creation    TIMESTAMP DEFAULT now(),
    PRIMARY KEY(ip,alias)
);

-- Indexing for speed ups
CREATE INDEX idx_device_ip_ip      ON device_ip(ip);
CREATE INDEX idx_device_ip_alias   ON device_ip(alias);
CREATE INDEX idx_device_ip_ip_port ON device_ip(ip,port);
