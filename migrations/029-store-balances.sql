create table mkr.balances (
  id serial primary key,
  address character(66) not null,
  amount decimal(78,18) not null,
  tx_id integer not null references vulcan2x.transaction(id) on delete cascade,
  block_id integer not null references vulcan2x.block(id) on delete cascade
);

create index address_index on mkr.balances (address);

-- to get the balance at a block:
--   select amount from mkr.balances
--     join vulcan2x.block on block.id = block_id
--     where address = a
--     and block.number <= b
--     order by block.number desc
--     limit 1