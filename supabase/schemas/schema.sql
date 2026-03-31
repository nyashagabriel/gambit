-- Private schema remains non-exposed; edge functions use public RPC wrappers.

revoke usage on schema gambit from anon, authenticated;
revoke all on all tables in schema gambit from anon, authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- Companies
-- ─────────────────────────────────────────────────────────────────────────────
create or replace function public.list_companies()
returns table (
	id uuid,
	name text,
	status text,
	warning_message text,
	created_at timestamptz
)
language sql
security definer
set search_path = gambit, public, pg_temp
as $$
	select c.id, c.name, c.status::text, c.warning_message, c.created_at
	from gambit.companies c
	order by c.created_at desc;
$$;

create or replace function public.create_company(
	p_name text,
	p_actor uuid
)
returns table (
	id uuid,
	name text,
	status text,
	warning_message text,
	created_at timestamptz
)
language plpgsql
security definer
set search_path = gambit, public, pg_temp
as $$
begin
	if p_name is null or btrim(p_name) = '' then
		raise exception 'Company name is required';
	end if;

	if length(btrim(p_name)) > 120 then
		raise exception 'Company name too long';
	end if;

	return query
	insert into gambit.companies (name, status, created_by)
	values (btrim(p_name), 'active'::gambit.company_status, p_actor)
	returning companies.id, companies.name, companies.status::text, companies.warning_message, companies.created_at;
end;
$$;

create or replace function public.update_company(
	p_company_id uuid,
	p_name text default null,
	p_status text default null,
	p_warning_message text default null
)
returns table (
	id uuid,
	name text,
	status text,
	warning_message text,
	created_at timestamptz
)
language plpgsql
security definer
set search_path = gambit, public, pg_temp
as $$
begin
	update gambit.companies c
	set
		name = case when p_name is not null then btrim(p_name) else c.name end,
		status = case when p_status is not null then p_status::gambit.company_status else c.status end,
		warning_message = case when p_warning_message is not null then nullif(p_warning_message, '') else c.warning_message end
	where c.id = p_company_id;

	if not found then
		raise exception 'Company not found';
	end if;

	return query
	select c.id, c.name, c.status::text, c.warning_message, c.created_at
	from gambit.companies c
	where c.id = p_company_id;
end;
$$;

create or replace function public.delete_company(p_company_id uuid)
returns void
language plpgsql
security definer
set search_path = gambit, public, pg_temp
as $$
begin
	delete from gambit.companies where id = p_company_id;
	if not found then
		raise exception 'Company not found';
	end if;
end;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- Shared audit
-- ─────────────────────────────────────────────────────────────────────────────
create or replace function public.insert_audit_log(
	p_actor_id uuid,
	p_actor_role text,
	p_company_id uuid,
	p_action text,
	p_target_type text,
	p_target_id uuid,
	p_details jsonb,
	p_ip_address text
)
returns void
language plpgsql
security definer
set search_path = gambit, public, pg_temp
as $$
begin
	insert into gambit.audit_log (
		actor_id, actor_role, company_id,
		action, target_type, target_id,
		details, ip_address
	)
	values (
		p_actor_id, p_actor_role, p_company_id,
		p_action, p_target_type, p_target_id,
		p_details, p_ip_address
	);
end;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- Auth
-- ─────────────────────────────────────────────────────────────────────────────
create or replace function public.auth_me(p_user_id uuid)
returns table (
	id uuid,
	username text,
	full_name text,
	role text,
	company_id uuid,
	is_active boolean,
	must_change_pw boolean,
	recovery_email text,
	created_at timestamptz
)
language sql
security definer
set search_path = gambit, public, pg_temp
as $$
	select u.id, u.username, u.full_name, u.role::text, u.company_id,
				 u.is_active, u.must_change_pw, u.recovery_email, u.created_at
	from gambit.users u
	where u.id = p_user_id
	limit 1;
$$;

create or replace function public.set_recovery_email(
	p_user_id uuid,
	p_email text
)
returns void
language plpgsql
security definer
set search_path = gambit, public, pg_temp
as $$
begin
	update gambit.users
	set recovery_email = p_email
	where id = p_user_id;

	if not found then
		raise exception 'User not found';
	end if;
end;
$$;

create or replace function public.create_company_admin_user(
	p_company_id uuid,
	p_username text,
	p_password_hash text,
	p_full_name text,
	p_created_by uuid
)
returns table (
	id uuid,
	username text,
	role text,
	company_id uuid,
	must_change_pw boolean,
	full_name text
)
language plpgsql
security definer
set search_path = gambit, public, pg_temp
as $$
begin
	return query
	insert into gambit.users (
		company_id,
		username,
		password_hash,
		role,
		full_name,
		must_change_pw,
		created_by
	)
	values (
		p_company_id,
		p_username,
		p_password_hash,
		'company_admin'::gambit.user_role,
		p_full_name,
		true,
		p_created_by
	)
	returning users.id, users.username, users.role::text, users.company_id, users.must_change_pw, users.full_name;
end;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- Users
-- ─────────────────────────────────────────────────────────────────────────────
create or replace function public.list_users(p_company_id uuid default null)
returns table (
	id uuid,
	username text,
	full_name text,
	role text,
	is_active boolean,
	company_id uuid,
	created_at timestamptz
)
language sql
security definer
set search_path = gambit, public, pg_temp
as $$
	select u.id, u.username, u.full_name, u.role::text, u.is_active, u.company_id, u.created_at
	from gambit.users u
	where p_company_id is null or u.company_id = p_company_id
	order by u.created_at desc;
$$;

create or replace function public.create_user(
	p_company_id uuid,
	p_username text,
	p_password_hash text,
	p_role text,
	p_full_name text,
	p_phone text,
	p_created_by uuid
)
returns table (
	id uuid,
	username text,
	role text,
	company_id uuid,
	must_change_pw boolean,
	full_name text
)
language plpgsql
security definer
set search_path = gambit, public, pg_temp
as $$
begin
	return query
	insert into gambit.users (
		company_id,
		username,
		password_hash,
		role,
		full_name,
		phone,
		must_change_pw,
		created_by
	) values (
		p_company_id,
		p_username,
		p_password_hash,
		p_role::gambit.user_role,
		p_full_name,
		p_phone,
		true,
		p_created_by
	)
	returning users.id, users.username, users.role::text, users.company_id, users.must_change_pw, users.full_name;
end;
$$;

create or replace function public.get_user_scope(p_user_id uuid)
returns table (
	id uuid,
	role text,
	company_id uuid
)
language sql
security definer
set search_path = gambit, public, pg_temp
as $$
	select u.id, u.role::text, u.company_id
	from gambit.users u
	where u.id = p_user_id
	limit 1;
$$;

create or replace function public.update_user(
	p_user_id uuid,
	p_is_active boolean default null,
	p_full_name text default null,
	p_phone text default null
)
returns table (
	id uuid,
	username text,
	role text,
	is_active boolean,
	full_name text,
	company_id uuid
)
language plpgsql
security definer
set search_path = gambit, public, pg_temp
as $$
begin
	update gambit.users u
	set
		is_active = case when p_is_active is not null then p_is_active else u.is_active end,
		full_name = case when p_full_name is not null then nullif(btrim(p_full_name), '') else u.full_name end,
		phone = case when p_phone is not null then nullif(btrim(p_phone), '') else u.phone end
	where u.id = p_user_id;

	if not found then
		raise exception 'User not found';
	end if;

	return query
	select u.id, u.username, u.role::text, u.is_active, u.full_name, u.company_id
	from gambit.users u
	where u.id = p_user_id;
end;
$$;

create or replace function public.reset_user_password(
	p_user_id uuid,
	p_password_hash text
)
returns void
language plpgsql
security definer
set search_path = gambit, public, pg_temp
as $$
begin
	update gambit.users
	set password_hash = p_password_hash,
			must_change_pw = true
	where id = p_user_id;

	if not found then
		raise exception 'User not found';
	end if;
end;
$$;

create or replace function public.delete_user(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = gambit, public, pg_temp
as $$
begin
	delete from gambit.users where id = p_user_id;
	if not found then
		raise exception 'User not found';
	end if;
end;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- Files/Documents
-- ─────────────────────────────────────────────────────────────────────────────
create or replace function public.create_document(
	p_company_id uuid,
	p_folder text,
	p_title text,
	p_storage_path text,
	p_expiry_date date,
	p_uploaded_by uuid
)
returns table (
	id uuid,
	title text,
	folder text,
	expiry_date date,
	storage_path text,
	created_at timestamptz
)
language plpgsql
security definer
set search_path = gambit, public, pg_temp
as $$
begin
	return query
	insert into gambit.documents (
		company_id, folder, title, file_path, expiry_date, uploaded_by
	) values (
		p_company_id,
		p_folder,
		p_title,
		p_storage_path,
		coalesce(p_expiry_date, (now() + interval '365 days')::date),
		p_uploaded_by
	)
	returning documents.id, documents.title, documents.folder, documents.expiry_date,
						documents.file_path as storage_path, documents.created_at;
end;
$$;

create or replace function public.list_documents(
	p_company_id uuid,
	p_folder text default null
)
returns table (
	id uuid,
	title text,
	folder text,
	expiry_date date,
	storage_path text,
	created_at timestamptz,
	uploaded_by uuid
)
language sql
security definer
set search_path = gambit, public, pg_temp
as $$
	select d.id, d.title, d.folder, d.expiry_date, d.file_path as storage_path, d.created_at, d.uploaded_by
	from gambit.documents d
	where d.company_id = p_company_id
		and (p_folder is null or d.folder = p_folder)
	order by d.created_at desc;
$$;

create or replace function public.get_document_scope(p_document_id uuid)
returns table (
	id uuid,
	storage_path text,
	company_id uuid
)
language sql
security definer
set search_path = gambit, public, pg_temp
as $$
	select d.id, d.file_path as storage_path, d.company_id
	from gambit.documents d
	where d.id = p_document_id
	limit 1;
$$;

create or replace function public.delete_document(p_document_id uuid)
returns void
language plpgsql
security definer
set search_path = gambit, public, pg_temp
as $$
begin
	delete from gambit.documents where id = p_document_id;
	if not found then
		raise exception 'Document not found';
	end if;
end;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- Core API (trips/fleet/drivers)
-- ─────────────────────────────────────────────────────────────────────────────
create or replace function public.list_trips(
	p_company_id uuid default null,
	p_driver_id uuid default null
)
returns table (
	id uuid,
	reference text,
	trip_type text,
	status text,
	origin text,
	destination text,
	cargo_type text,
	cargo_description text,
	tonnage numeric,
	freight_rate numeric,
	start_date date,
	end_date date,
	created_at timestamptz,
	horse jsonb,
	driver jsonb
)
language sql
security definer
set search_path = gambit, public, pg_temp
as $$
	select
		t.id,
		t.reference,
		t.trip_type,
		t.status::text,
		t.origin,
		t.destination,
		t.cargo_type,
		t.cargo_description,
		t.tonnage,
		t.freight_rate,
		t.start_date,
		t.end_date,
		t.created_at,
		jsonb_build_object('id', f.id, 'registration', f.reg_number) as horse,
		jsonb_build_object('id', d.id, 'full_name', concat_ws(' ', d.first_name, d.middle_name, d.last_name)) as driver
	from gambit.trips t
	left join gambit.fleet f on f.id = t.horse_id
	left join gambit.drivers d on d.id = t.driver_id
	where (p_company_id is null or t.company_id = p_company_id)
		and (p_driver_id is null or t.driver_id = p_driver_id)
	order by t.created_at desc;
$$;

create or replace function public.create_trip(
	p_company_id uuid,
	p_reference text,
	p_trip_type text,
	p_horse_id uuid,
	p_driver_id uuid,
	p_origin text,
	p_destination text,
	p_cargo_type text,
	p_cargo_description text,
	p_tonnage numeric,
	p_freight_rate numeric,
	p_start_date date,
	p_end_date date,
	p_created_by uuid
)
returns table (
	id uuid,
	company_id uuid,
	reference text,
	trip_type text,
	horse_id uuid,
	driver_id uuid,
	origin text,
	destination text,
	cargo_type text,
	cargo_description text,
	tonnage numeric,
	freight_rate numeric,
	start_date date,
	end_date date,
	status text,
	created_at timestamptz
)
language plpgsql
security definer
set search_path = gambit, public, pg_temp
as $$
begin
	return query
	insert into gambit.trips (
		company_id, reference, trip_type, horse_id, driver_id,
		origin, destination, cargo_type, cargo_description,
		tonnage, freight_rate, start_date, end_date,
		status, created_by
	)
	values (
		p_company_id,
		p_reference,
		p_trip_type,
		p_horse_id,
		p_driver_id,
		p_origin,
		p_destination,
		p_cargo_type,
		p_cargo_description,
		p_tonnage,
		p_freight_rate,
		p_start_date,
		p_end_date,
		'pending'::gambit.trip_status,
		p_created_by
	)
	returning
		trips.id, trips.company_id, trips.reference, trips.trip_type::text,
		trips.horse_id, trips.driver_id, trips.origin, trips.destination,
		trips.cargo_type, trips.cargo_description, trips.tonnage, trips.freight_rate,
		trips.start_date, trips.end_date, trips.status::text, trips.created_at;
end;
$$;

create or replace function public.get_trip_scope(p_trip_id uuid)
returns table (
	id uuid,
	company_id uuid,
	driver_id uuid,
	status text
)
language sql
security definer
set search_path = gambit, public, pg_temp
as $$
	select t.id, t.company_id, t.driver_id, t.status::text
	from gambit.trips t
	where t.id = p_trip_id
	limit 1;
$$;

create or replace function public.update_trip(
	p_trip_id uuid,
	p_status text default null,
	p_pod_number text default null,
	p_odo_reading numeric default null,
	p_notes text default null,
	p_horse_id uuid default null,
	p_driver_id uuid default null,
	p_freight_rate numeric default null,
	p_start_date date default null,
	p_end_date date default null
)
returns table (
	id uuid,
	company_id uuid,
	reference text,
	trip_type text,
	horse_id uuid,
	driver_id uuid,
	origin text,
	destination text,
	cargo_type text,
	cargo_description text,
	tonnage numeric,
	freight_rate numeric,
	start_date date,
	end_date date,
	status text,
	pod_number text,
	odo_reading numeric,
	notes text,
	created_at timestamptz
)
language plpgsql
security definer
set search_path = gambit, public, pg_temp
as $$
begin
	update gambit.trips t
	set
		status = case when p_status is not null then p_status::gambit.trip_status else t.status end,
		driver_notes = jsonb_strip_nulls(
			coalesce(t.driver_notes, '{}'::jsonb)
			|| case when p_pod_number is not null then jsonb_build_object('pod_number', p_pod_number) else '{}'::jsonb end
			|| case when p_odo_reading is not null then jsonb_build_object('odo_reading', p_odo_reading) else '{}'::jsonb end
			|| case when p_notes is not null then jsonb_build_object('notes', p_notes) else '{}'::jsonb end
		),
		horse_id = case when p_horse_id is not null then p_horse_id else t.horse_id end,
		driver_id = case when p_driver_id is not null then p_driver_id else t.driver_id end,
		freight_rate = case when p_freight_rate is not null then p_freight_rate else t.freight_rate end,
		start_date = case when p_start_date is not null then p_start_date else t.start_date end,
		end_date = case when p_end_date is not null then p_end_date else t.end_date end
	where t.id = p_trip_id;

	if not found then
		raise exception 'Trip not found';
	end if;

	return query
	select
		t.id, t.company_id, t.reference, t.trip_type,
		t.horse_id, t.driver_id, t.origin, t.destination,
		t.cargo_type, t.cargo_description, t.tonnage, t.freight_rate,
		t.start_date, t.end_date, t.status::text,
		t.driver_notes->>'pod_number' as pod_number,
		nullif(t.driver_notes->>'odo_reading', '')::numeric as odo_reading,
		t.driver_notes->>'notes' as notes,
		t.created_at
	from gambit.trips t
	where t.id = p_trip_id;
end;
$$;

create or replace function public.list_fleet(p_company_id uuid default null)
returns table (
	id uuid,
	registration text,
	vehicle_type text,
	status text,
	make text,
	model text,
	year int,
	created_at timestamptz
)
language sql
security definer
set search_path = gambit, public, pg_temp
as $$
	select f.id, f.reg_number as registration, f.vehicle_type, f.status::text, null::text as make, f.model, f.year, f.created_at
	from gambit.fleet f
	where p_company_id is null or f.company_id = p_company_id
	order by f.created_at desc;
$$;

create or replace function public.list_drivers(p_company_id uuid default null)
returns table (
	id uuid,
	full_name text,
	license_number text,
	phone text,
	is_active boolean,
	created_at timestamptz
)
language sql
security definer
set search_path = gambit, public, pg_temp
as $$
	select d.id,
		concat_ws(' ', d.first_name, d.middle_name, d.last_name) as full_name,
		d.license_number,
		d.phone,
		(coalesce(d.status::text, '') <> 'inactive') as is_active,
		d.created_at
	from gambit.drivers d
	where p_company_id is null or d.company_id = p_company_id
	order by full_name asc;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- Grants (service role only)
-- ─────────────────────────────────────────────────────────────────────────────
revoke all on function public.list_companies() from public, anon, authenticated;
revoke all on function public.create_company(text, uuid) from public, anon, authenticated;
revoke all on function public.update_company(uuid, text, text, text) from public, anon, authenticated;
revoke all on function public.delete_company(uuid) from public, anon, authenticated;
revoke all on function public.insert_audit_log(uuid, text, uuid, text, text, uuid, jsonb, text) from public, anon, authenticated;
revoke all on function public.auth_me(uuid) from public, anon, authenticated;
revoke all on function public.set_recovery_email(uuid, text) from public, anon, authenticated;
revoke all on function public.create_company_admin_user(uuid, text, text, text, uuid) from public, anon, authenticated;
revoke all on function public.list_users(uuid) from public, anon, authenticated;
revoke all on function public.create_user(uuid, text, text, text, text, text, uuid) from public, anon, authenticated;
revoke all on function public.get_user_scope(uuid) from public, anon, authenticated;
revoke all on function public.update_user(uuid, boolean, text, text) from public, anon, authenticated;
revoke all on function public.reset_user_password(uuid, text) from public, anon, authenticated;
revoke all on function public.delete_user(uuid) from public, anon, authenticated;
revoke all on function public.create_document(uuid, text, text, text, date, uuid) from public, anon, authenticated;
revoke all on function public.list_documents(uuid, text) from public, anon, authenticated;
revoke all on function public.get_document_scope(uuid) from public, anon, authenticated;
revoke all on function public.delete_document(uuid) from public, anon, authenticated;
revoke all on function public.list_trips(uuid, uuid) from public, anon, authenticated;
revoke all on function public.create_trip(uuid, text, text, uuid, uuid, text, text, text, text, numeric, numeric, date, date, uuid) from public, anon, authenticated;
revoke all on function public.get_trip_scope(uuid) from public, anon, authenticated;
revoke all on function public.update_trip(uuid, text, text, numeric, text, uuid, uuid, numeric, date, date) from public, anon, authenticated;
revoke all on function public.list_fleet(uuid) from public, anon, authenticated;
revoke all on function public.list_drivers(uuid) from public, anon, authenticated;

grant execute on function public.list_companies() to service_role;
grant execute on function public.create_company(text, uuid) to service_role;
grant execute on function public.update_company(uuid, text, text, text) to service_role;
grant execute on function public.delete_company(uuid) to service_role;
grant execute on function public.insert_audit_log(uuid, text, uuid, text, text, uuid, jsonb, text) to service_role;
grant execute on function public.auth_me(uuid) to service_role;
grant execute on function public.set_recovery_email(uuid, text) to service_role;
grant execute on function public.create_company_admin_user(uuid, text, text, text, uuid) to service_role;
grant execute on function public.list_users(uuid) to service_role;
grant execute on function public.create_user(uuid, text, text, text, text, text, uuid) to service_role;
grant execute on function public.get_user_scope(uuid) to service_role;
grant execute on function public.update_user(uuid, boolean, text, text) to service_role;
grant execute on function public.reset_user_password(uuid, text) to service_role;
grant execute on function public.delete_user(uuid) to service_role;
grant execute on function public.create_document(uuid, text, text, text, date, uuid) to service_role;
grant execute on function public.list_documents(uuid, text) to service_role;
grant execute on function public.get_document_scope(uuid) to service_role;
grant execute on function public.delete_document(uuid) to service_role;
grant execute on function public.list_trips(uuid, uuid) to service_role;
grant execute on function public.create_trip(uuid, text, text, uuid, uuid, text, text, text, text, numeric, numeric, date, date, uuid) to service_role;
grant execute on function public.get_trip_scope(uuid) to service_role;
grant execute on function public.update_trip(uuid, text, text, numeric, text, uuid, uuid, numeric, date, date) to service_role;
grant execute on function public.list_fleet(uuid) to service_role;
grant execute on function public.list_drivers(uuid) to service_role;
