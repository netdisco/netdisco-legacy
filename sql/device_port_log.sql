-- $Id$

DROP TABLE device_port_log;
DROP SEQUENCE device_port_log_id_seq;

CREATE TABLE device_port_log (
    id          serial, 
    ip          inet,
    port        text,
    reason      text,
    log         text, 
    username    text,   -- user is a reserved word
    userip      inet,
    action      text,
    creation    TIMESTAMP DEFAULT now()
                             );

CREATE INDEX idx_device_port_log_1 ON device_port_log(ip,port);
CREATE INDEX idx_device_port_log_user ON device_port_log(username);
