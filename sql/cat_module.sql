-- $Id$

DROP TABLE cat_module;

CREATE TABLE cat_module (
    ip          inet,   -- device IP
    module      int,
    creation    TIMESTAMP DEFAULT now(),
    type        text,
    model       text,
    serial      text,
    status      text,   
    name        text,
    ports       integer,
    hwver       text,
    swver       text,
    fwver       text,
    mod_ip      inet,   -- IP if router module
    sub1        text,   -- sub module1
    sub2        text,   -- sub module2
    PRIMARY KEY(module,ip)
);
