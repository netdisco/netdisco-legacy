-- admin table - Queue for admin tasks sent from front-end for back-end processing.
-- $Id$ 

DROP TABLE admin;
DROP SEQUENCE admin_job_seq;

CREATE TABLE admin (
    job         serial,
    entered     TIMESTAMP DEFAULT now(),
    started     TIMESTAMP,
    finished    TIMESTAMP,
    device      inet,
    port        text,
    action      text, -- delete, delete+nodes, macsuck, arpnip, refresh, vlan
    subaction   text, -- free field to be used for each action
    status      text, -- queued, running, done, error, del
    username    text,
    userip      inet,
    log         text,
    debug       boolean
                   );

CREATE INDEX idx_admin_entered    ON admin(entered);
