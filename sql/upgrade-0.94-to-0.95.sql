-- Netdisco
-- Database Schema Modifications
-- UPGRADE from 0.94 to 0.95
-- $Id$

CREATE TABLE subnets (
    net cidr NOT NULL,
    creation timestamp default now(),
    last_discover timestamp default now(),
    PRIMARY KEY(net)
);
