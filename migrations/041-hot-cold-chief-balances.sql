--replaces function in 036 to include the hot wallet and cold wallet's chief balance
-- this function only works with addresses that are proxies or unlinked addresses,
-- NOT hot or cold wallet addresses.
create or replace function polling.reverse_voter_weight(address character(42), block_id integer)
returns decimal(78,18) as $$
declare
  wallet_amount decimal(78,18);
  chief_amount decimal(78,18);
  proxy dschief.vote_proxy_created_event%rowtype;
  hot_wallet_amount decimal(78,18);
  cold_wallet_amount decimal(78,18);
  hot_chief_amount decimal(78,18);
  cold_chief_amount decimal(78,18);
begin
  select amount into wallet_amount from mkr.balances ba
  where ba.address = reverse_voter_weight.address
  and ba.block_id <= reverse_voter_weight.block_id
  order by ba.id desc limit 1;

  select amount into chief_amount from dschief.balances ba
  where ba.address = reverse_voter_weight.address
  and ba.block_id <= reverse_voter_weight.block_id
  order by ba.id desc limit 1;

  -- if address is a proxy, add balances for hot & cold wallets

  select * into proxy
  from dschief.vote_proxy_created_event vpc
  where vote_proxy = reverse_voter_weight.address
  and vpc.block_id <= reverse_voter_weight.block_id
  order by vpc.id desc limit 1;

  if proxy is not null then
    select amount into hot_wallet_amount from mkr.balances ba
    where ba.address = proxy.hot
    and ba.block_id <= reverse_voter_weight.block_id
    order by ba.id desc limit 1;

    select amount into hot_chief_amount from dschief.balances ba
    where ba.address = proxy.hot
    and ba.block_id <= reverse_voter_weight.block_id
    order by ba.id desc limit 1;

    if proxy.hot != proxy.cold then
      select amount into cold_wallet_amount from mkr.balances ba
      where ba.address = proxy.cold
      and ba.block_id <= reverse_voter_weight.block_id
      order by ba.id desc limit 1;

      select amount into cold_chief_amount from dschief.balances ba
      where ba.address = proxy.cold
      and ba.block_id <= reverse_voter_weight.block_id
      order by ba.id desc limit 1;
    end if;
  end if;

  return coalesce(wallet_amount, 0) + 
    coalesce(chief_amount, 0) + 
    coalesce(hot_wallet_amount, 0) +
    coalesce(cold_wallet_amount, 0) +
    coalesce(hot_chief_amount, 0) +
    coalesce(cold_chief_amount, 0);
end;
$$ language plpgsql stable strict;