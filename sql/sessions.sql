-- $Id$

DROP TABLE sessions;

CREATE TABLE sessions (
    id          char(32) NOT NULL PRIMARY KEY,
    creation    TIMESTAMP DEFAULT now(),
    a_session   text
                       );
