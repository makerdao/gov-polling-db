-- Dropping function as the return type changed
drop function if exists api.delegates;

drop type delegate_entry;

create type delegate_entry as (
  delegate character varying(66),
  vote_delegate character varying(66),
  creation_date timestamp with time zone,
  expiration_date timestamp with time zone,
  expired boolean,
  last_voted timestamp with time zone,
  delegator_count int,
  total_mkr numeric(78,18),
  delegate_version int
);

-- Same function, but also return the delegate version
create or replace function api.delegates(_first int, order_by delegate_order_by_type default 'DATE', order_direction order_direction_type default 'DESC', include_expired boolean default false, seed double precision default random(), constitutional_delegates char[] default '{}')
returns setof delegate_entry as $$
declare
  max_page_size_value int := (select api.max_page_size());
begin
  if _first > max_page_size_value then
    raise exception 'Parameter FIRST cannot be greater than %.', max_page_size_value;
  elsif seed > 1 or seed < -1 then
    raise exception 'Parameter SEED must have a value between -1 and 1';
  else
    return query
      -- Merge poll votes from Mainnet and Arbitrum and attach the timestamp to them
      with merged_vote_events as (
        select voter, vote_timestamp
        from (
          select voter, timestamp as vote_timestamp
          from polling.voted_event A
          left join vulcan2x.block B
          on A.block_id = B.id
        ) AB
        union all
        select voter, vote_timestamp
        from (
          select voter, timestamp as vote_timestamp
          from polling.voted_event_arbitrum C
          left join vulcan2xarbitrum.block D
          on C.block_id = D.id
        ) CD
      ),
      delegates_table as (
        select E.delegate, E.vote_delegate, F.timestamp as creation_date, F.timestamp + '1 year' as expiration_date, now() > F.timestamp + '1 year' as expired, E.delegate_version
        from dschief.vote_delegate_created_event E
        left join vulcan2x.block F
        on E.block_id = F.id
        -- Filter out expired delegates if include_expired is false
        where include_expired or now() < F.timestamp + '1 year'
      ),
      -- Merge delegates with their last votes
      delegates_with_last_vote as (
        select G.*, max(H.vote_timestamp) as last_voted
        from delegates_table G
        left join merged_vote_events H
        on G.vote_delegate = H.voter
        group by G.vote_delegate, G.delegate, G.creation_date, G.expiration_date, G.expired, G.delegate_version
      ),
      delegations_table as (
        select contract_address, count(immediate_caller) as delegators, sum(delegations) as delegations
        from (
          select immediate_caller, sum(lock) as delegations, contract_address
          from dschief.delegate_lock
          group by contract_address, immediate_caller
        ) as I
        where delegations > 0
        group by contract_address
      )
      select delegate::character varying(66), vote_delegate::character varying(66), creation_date, expiration_date, expired, last_voted, coalesce(delegators, 0)::int as delegator_count, coalesce(delegations, 0)::numeric(78,18) as total_mkr, delegate_version
      from (
        -- We call setseed here to make sure it's executed before the main select statement and the order by random clause.
        -- By appending it to the delegates_with_last_vote table and then removing the row with offset 1, we make sure the table remains unmodified.
        select setseed(seed), null delegate, null vote_delegate, null creation_date, null expiration_date, null expired, null last_voted, null delegate_version
        union all
        select null, delegate, vote_delegate, creation_date, expiration_date, expired, last_voted, delegate_version from delegates_with_last_vote
        offset 1
      ) sd
      left join delegations_table
      on sd.vote_delegate::character varying(66) = delegations_table.contract_address
      order by 
        -- Ordering first by expiration: expired at the end, second by delegate type: constitutional delegates first
        -- and third by the sorting criterion selected.
        case when expired then 1 else 0 end,
        case when vote_delegate = ANY (constitutional_delegates) then 0 else 1 end,
        case
          when order_by = 'DELEGATORS' then
            case when order_direction = 'ASC' then coalesce(delegators, 0)::int else -coalesce(delegators, 0)::int end
          when order_by = 'MKR' then
            case when order_direction = 'ASC' then coalesce(delegations, 0)::numeric(78,18) else -coalesce(delegations, 0)::numeric(78,18) end
          when order_by = 'DATE' then
            case when order_direction = 'ASC' then extract(epoch from creation_date) else -extract(epoch from creation_date) end
          else
            random()
        end;
  end if;
end;
$$ language plpgsql stable strict;