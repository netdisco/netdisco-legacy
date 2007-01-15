-- process table - Queue to coordinate between processes in multi-process mode.
-- $Id$

DROP TABLE process;
CREATE TABLE process (
    controller  integer not null, -- pid of controlling process
    device      inet not null,
    action      text not null,    -- arpnip, macsuck, nbtstat, discover
    status      text,    	  -- queued, running, skipped, done, error, timeout, nocdp, nosnmp
    count       integer
    );
