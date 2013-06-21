DROP TABLE topology;

-- Add "topology" table to augment manual topo file
CREATE TABLE topology (
    dev1   inet not null, -- Device on "left" side of topo relation
    port1  text not null, -- Port on "left" device
    dev2   inet not null, -- Device on "right" side of topo relation
    port2  text not null  -- Port on "right" device
);


