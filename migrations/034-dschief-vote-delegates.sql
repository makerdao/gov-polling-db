CREATE TABLE dschief.vote_delegate_created_event (
  id         serial primary key,
  delegate             character varying(66) not null,
  vote_delegate              character varying(66) not null,
  
  log_index  integer not null,
  tx_id      integer not null REFERENCES vulcan2x.transaction(id) ON DELETE CASCADE,
  block_id   integer not null REFERENCES vulcan2x.block(id) ON DELETE CASCADE,
  unique (log_index, tx_id)
);