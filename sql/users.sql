-- $Id$

DROP TABLE users;

CREATE TABLE users (
    username        varchar(50) PRIMARY KEY,
    password        text,   -- md5 
    creation        TIMESTAMP DEFAULT now(),
    last_on         TIMESTAMP,
    port_control    boolean DEFAULT false,
    admin           boolean DEFAULT false
                    );
