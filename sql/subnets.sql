-- $Id$

DROP TABLE subnets;

CREATE TABLE subnets (
    net cidr NOT NULL,
    creation timestamp default now(),
    last_discover timestamp default now(),
    PRIMARY KEY(net)
);
