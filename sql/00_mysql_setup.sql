-- 1) Create DB
create database if not exists aqi;

-- 2) Create a dedicated user (recommended)
-- Change password if you want
create user if not exists 'aqi_user'@'localhost' identified by 'aqi_pass';
grant all privileges on aqi.* to 'aqi_user'@'localhost';
flush privileges;

use aqi;

-- 3) Raw table (JSON landing)
create table if not exists raw_air_quality_observations (
  ingested_at timestamp not null default current_timestamp,
  source varchar(50) not null default 'data.gov.in',
  record json not null,
  record_hash varchar(64) not null,
  primary key (record_hash, ingested_at)
);

create index idx_ingested_at on raw_air_quality_observations (ingested_at);

-- Helpful generated columns for faster filtering (optional but useful)
alter table raw_air_quality_observations
  add column if not exists city varchar(120)
    generated always as (json_unquote(json_extract(record, '$.city'))) stored,
  add column if not exists station varchar(180)
    generated always as (json_unquote(json_extract(record, '$.station'))) stored,
  add index if not exists idx_city (city),
  add index if not exists idx_station (station);
