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
    action      text, -- delete, delete+nodes, macsuck, arpnip, refresh
    status      text, -- queued, running, done, error, del
    username    text,
    log         text,
    debug       boolean
                   );