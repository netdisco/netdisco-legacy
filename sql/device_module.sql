-- $Id$

DROP TABLE device_module;

CREATE TABLE device_module (
    ip            inet not null,
    index         integer,
    description   text,
    type          text,
    parent        integer,
    name          text,
    class         text,
    pos           integer,
    hw_ver        text,
    fw_ver        text,
    sw_ver        text,
    serial        text,
    model         text,
    fru           boolean,
    creation      TIMESTAMP DEFAULT now(),
    last_discover TIMESTAMP,
    PRIMARY KEY(ip,index)
    );
