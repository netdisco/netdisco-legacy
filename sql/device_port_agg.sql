
DROP TABLE device_port_agg;

CREATE TABLE device_port_agg (
    ip          inet,   -- ip of device
    port        text,   -- Unique identifier of Physical Port Name
    aggregate   text,   -- Unique identifier of Aggregate Port
    created     timestamp default now(),
    last_seen   timestamp default now(),
    PRIMARY KEY(port,ip) 
);

-- For "what ports are member of this aggregate?"
CREATE INDEX idx_device_port_agg_aggregate ON device_port_agg(ip,aggregate);
