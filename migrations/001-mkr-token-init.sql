CREATE SCHEMA mkr;

CREATE TABLE mkr.transfer_event (
  id         serial primary key,
  sender     character varying(66) not null,
  receiver   character varying(66) not null,
  amount     decimal(78,18) not null,
  
  log_index  integer not null,
  tx_id      integer not null REFERENCES vulcan2x.transaction(id) ON DELETE CASCADE,
  block_id   integer not null REFERENCES vulcan2x.block(id) ON DELETE CASCADE,
  unique (log_index, tx_id)
);