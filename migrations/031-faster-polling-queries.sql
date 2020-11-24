create index poll_id_index on polling.voted_event (poll_id);
create index sender_index on mkr.transfer_event (sender);
create index receiver_index on mkr.transfer_event (receiver);
create index block_id_index on mkr.transfer_event (block_id);
create index timestamp_index on vulcan2x.block (timestamp);

create or replace function polling.weight_at_block(address character(66), block_id integer)
returns decimal(78,18) as $$
declare
  wallet_amount decimal(78,18);
  chief_amount decimal(78,18);
  proxy%rowtype;
  proxy_wallet_amount decimal(78,18);
  proxy_chief_amount decimal(78,18);
  linked_wallet_amount decimal(78,18);
begin
  select amount into wallet_amount from mkr.balances ba
  where ba.address = weight_at_block.address
  and ba.block_id <= weight_at_block.block_id
  order by ba.id desc limit 1;

  select amount into chief_amount from dschief.balances ba
  where ba.address = weight_at_block.address
  and ba.block_id <= weight_at_block.block_id
  order by ba.id desc limit 1;

  select vote_proxy, hot into proxy_result
  from dschief.vote_proxy_created_event vpc
  where (hot = weight_at_block.address or cold = weight_at_block.address)
  and vpc.block_id <= weight_at_block.block_id
  order by vpc.id desc limit 1;

  if proxy is not null then
    select amount into proxy_wallet_amount from mkr.balances ba
    where ba.address = proxy.vote_proxy
    and ba.block_id <= weight_at_block.block_id
    order by ba.id desc limit 1;

    select amount into proxy_chief_amount from dschief.balances ba
    where ba.address = proxy.vote_proxy
    and ba.block_id <= weight_at_block.block_id
    order by ba.id desc limit 1;

    select amount into linked_wallet_amount from mkr.balances ba
    where ba.address = (
      case when proxy.cold = weight_at_block.address
      then proxy.hot else proxy.cold)
    and ba.block_id <= weight_at_block.block_id
    order by ba.id desc limit 1;
  end if;

  return coalesce(wallet_amount, 0) + 
    coalesce(chief_amount, 0) + 
    coalesce(proxy_wallet_amount, 0) + 
    coalesce(proxy_chief_amount, 0) + ;
    coalesce(linked_wallet_amount, 0);
end;
$$ language plpgsql stable strict;

create or replace function polling.weighted_votes_at_block(poll_id integer, block_id integer)
returns table (
  voter character(66),
  option_id integer,
  amount decimal(78,18)
) as $$
  select 
    voter, 
    option_id, 
    polling.weight_at_block(voter, weighted_votes_at_block.block_id)
  from polling.valid_votes(weighted_votes_at_block.poll_id) vv
  where vv.block_id <= weighted_votes_at_block.block_id
$$ language sql stable strict;

create or replace function polling.tally_at_block(poll_id integer, block_id integer)
returns table (
  option_id integer,
  amount decimal(78,18)
) as $$
  select
    option_id, 
    sum(amount)
  from polling.weighted_votes_at_block(poll_id, block_id)
  group by option_id order by option_id asc;
$$ language sql stable strict;

create or replace function polling.tally_at_block_number(poll_id integer, block_number integer)
returns table (
  option_id integer,
  amount decimal(78,18)
) as $$
  select
    option_id, 
    sum(amount)
  from polling.weighted_votes_at_block(poll_id, (
    select id from vulcan2x.block where number = block_number
  ))
  group by option_id order by option_id asc;
$$ language sql stable strict;
