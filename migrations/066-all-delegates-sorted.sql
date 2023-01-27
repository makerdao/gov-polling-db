create type order_direction_type as enum ('ASC', 'DESC');
create type order_by_type as enum ('DATE', 'MKR', 'DELEGATORS');
create type delegate_entry as (
  delegate character varying(66),
  vote_delegate character varying(66),
  creation_date timestamp with time zone,
  expiration_date timestamp with time zone,
  expired boolean,
  delegator_count int,
  total_mkr numeric(78,18)
);

-- Small function used to return the max page size for paginated endpoints
create or replace function api.max_page_size()
returns int as $$
select 30
$$ language sql stable strict;

create or replace function api.delegates(_first int, order_by order_by_type default 'DATE', order_direction order_direction_type default 'DESC', include_expired boolean default false)
returns setof delegate_entry as $$
declare
  max_page_size_value int := (select api.max_page_size());
begin
  if _first > max_page_size_value then
    raise exception 'Parameter FIRST cannot be greater than %.', max_page_size_value
    return;
  else
    return query
      with delegates_table as (
        select A.delegate, A.vote_delegate, B.timestamp as creation_date, B.timestamp + '1 year' as expiration_date, now() > B.timestamp + '1 year' as expired
        from dschief.vote_delegate_created_event A
        left join vulcan2x.block B
        on A.block_id = B.id
        -- Filter out expired delegates if include_expired is false
        where include_expired or now() < B.timestamp + '1 year'
      ), delegations_table as (
        select contract_address, count(immediate_caller) as delegators, sum(delegations) as delegations
          from (
            select immediate_caller, sum(lock) as delegations, contract_address
            from dschief.delegate_lock
            group by contract_address, immediate_caller
          ) as D
          where delegations > 0
          group by contract_address
      )
      select delegates_table.*, coalesce(delegators, 0)::int as delegator_count, coalesce(delegations, 0)::numeric(78,18) as total_mkr
      from delegates_table
      left join delegations_table
      on delegates_table.vote_delegate = delegations_table.contract_address
      order by case
        when order_by = 'DELEGATORS' then
          case when order_direction = 'ASC' then coalesce(delegators, 0)::int else -coalesce(delegators, 0)::int end
        when order_by = 'MKR' then
          case when order_direction = 'ASC' then coalesce(delegations, 0)::numeric(78,18) else -coalesce(delegations, 0)::numeric(78,18) end
        else
          case when order_direction = 'ASC' then extract(epoch from creation_date) else -extract(epoch from creation_date) end
        end;
  end if;
end;
$$ language plpgsql stable strict;