DROP TABLE device;

CREATE TABLE device (
    ip           inet PRIMARY KEY,
    creation     TIMESTAMP DEFAULT now(),
    dns          text,
    description  text,
    uptime       bigint,
    contact      text,
    name         text,
    location     text,
    layers       text,
    ports        integer,
    mac          macaddr,
    serial       text,
    model        text,
    ps1_type     text,
    ps2_type     text,
    ps1_status   text,
    ps2_status   text,
    fan          text,
    slots        integer,
    vendor       text,
    log          text
    last_discover TIMESTAMP,
    last_macsuck  TIMESTAMP,
    last_arpnip   TIMESTAMP
);

-- Indexing for speed-ups
CREATE INDEX idx_device_dns    ON device(dns);
CREATE INDEX idx_device_layers ON device(layers);
