CREATE TABLE dschief.delegate_lock (
  id         serial primary key,
  from_address             character varying(66) not null,
  immediate_caller    character varying(66) not null,
  lock       decimal(78,18) not null,
  contract_address    character varying(66) not null,
  
  log_index  integer not null,
  tx_id      integer not null REFERENCES vulcan2x.transaction(id) ON DELETE CASCADE,
  block_id   integer not null REFERENCES vulcan2x.block(id) ON DELETE CASCADE,
  unique (log_index, tx_id)
);
CREATE INDEX delegate_lock_block_id_index ON dschief.delegate_lock(block_id);