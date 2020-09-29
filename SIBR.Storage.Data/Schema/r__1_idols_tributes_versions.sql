﻿drop materialized view if exists idols_versions;
create materialized view idols_versions as
    select update_id, version, first_seen, last_seen, data from versions_view where type = 5;
create unique index idols_versions_pkey on idols_versions (version);

drop materialized view if exists tributes_hourly;
drop materialized view if exists tributes_by_player;
drop materialized view if exists tributes_versions;
create materialized view tributes_versions as
    select update_id, version, first_seen, last_seen, data from versions_view where type = 6 order by version;
create unique index tributes_versions_pkey on tributes_versions (version);

create materialized view tributes_by_player as
    select
        update_id,
        first_seen as timestamp,
        (jsonb_array_elements(data) -> 'peanuts')::int as peanuts,
        (jsonb_array_elements(data) ->> 'playerId')::uuid as player_id
    from tributes_versions;
create unique index on tributes_by_player (timestamp, update_id, player_id);

create materialized view tributes_hourly as
    select
        (array_agg(update_id))[1] as update_id,
        date_trunc('hour', timestamp) as timestamp,
        player_id,
        min(peanuts) as peanuts
    from tributes_by_player
    group by date_trunc('hour', timestamp), player_id;
create unique index on tributes_hourly (timestamp, update_id, player_id);