-- update polling.voted_event table to have chain_id
ALTER TABLE polling.voted_event
ADD COLUMN chain_id integer;

-- copied from 002, includes updates from 021
CREATE TABLE polling.voted_event_arbitrum (
  id              serial primary key,
  voter           character varying(66) not null,
  poll_id         integer not null,
  option_id       integer,
  option_id_raw   character varying(66),
  
  log_index  integer not null,
  tx_id      integer not null REFERENCES vulcan2xarbitrum.transaction(id) ON DELETE CASCADE,
  block_id   integer not null REFERENCES vulcan2xarbitrum.block(id) ON DELETE CASCADE,
  chain_id   integer not null,
  unique (log_index, tx_id)
);

CREATE INDEX arbitrum_poll_id_index ON polling.voted_event_arbitrum (poll_id);