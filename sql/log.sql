DROP TABLE log;
DROP SEQUENCE log_id_seq;

CREATE TABLE log (
    id          serial,
    creation    TIMESTAMP DEFAULT now(),
    class       text,
    entry       text
);
