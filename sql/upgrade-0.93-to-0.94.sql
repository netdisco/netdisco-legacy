-- Netdisco
-- Database Schema Modifications
-- UPGRADE from 0.93 to 0.94
-- $Id$

ALTER TABLE device_port ADD COLUMN lastchange bigint;

CREATE TABLE user_log (
    entry           serial,
    username        varchar(50),
    userip          inet,
    event           text,
    details         text,
    creation        TIMESTAMP DEFAULT now()
                      );
