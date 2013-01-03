-- Add "vlan" column to node table
ALTER TABLE node ADD vlan text default '0';

alter table node drop constraint node_pkey;
alter table node add primary key (mac, switch, port, vlan);
