-- $Id$
-- This table logs login and logout / change requests for users

DROP TABLE user_log;
DROP SEQUENCE user_log_entry_seq;

CREATE TABLE user_log (
    entry           serial,
    username        varchar(50),
    userip          inet,
    event           text,
    details         text,
    creation        TIMESTAMP DEFAULT now()
                      );
