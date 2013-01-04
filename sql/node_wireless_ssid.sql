-- Add "ssid" column to node_wireless table
ALTER TABLE node_wireless ADD ssid text default '';

alter table node_wireless drop constraint node_wireless_pkey;
alter table node_wireless add primary key (mac, ssid);


