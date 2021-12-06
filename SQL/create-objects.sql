if schema_id('api') is null
begin
    execute ('create schema [api]');
end;
go

if user_id('online-gaming-user') is null
begin
    create user [online-gaming-user] with password = 'Super_Str0ng*P@ZZword!';
end;

grant execute on schema::[api] to [online-gaming-user];
go

drop procedure if exists api.put_player_data;
drop procedure if exists api.get_player_data;
drop table if exists api.player_state;
create table api.player_state
(
	[id] uniqueidentifier constraint [IX_Hash_Key] primary key nonclustered hash ([id]) with (bucket_count = 1000000)  not null,	
	[state] nvarchar(max) not null
) 
with (memory_optimized = on, durability = schema_and_data);
go

create or alter procedure api.put_player_data
@id uniqueidentifier,
@payload nvarchar(max)
with native_compilation, schemabinding
as 
begin atomic with (transaction isolation level = snapshot, language = N'us_english')
	if (isjson(@payload) <> 1) throw 50000, '@value is not a JSON object', 16;	

	update api.player_state set [state] = @payload where [id] = @id;
	if (@@rowcount = 0) begin
		insert into api.player_state ([id], [state]) values (@id, @payload)
	end	
end
go


create or alter procedure api.get_player_data
@id uniqueidentifier
with native_compilation, schemabinding
as 
begin atomic with (transaction isolation level = snapshot, language = N'us_english')
		
	select [state] from api.player_state where [id] = @id;

end
go

declare @id as uniqueidentifier = '69201DAB-70F8-48DB-9D0B-9A261EC73E7B';
declare @p as nvarchar(max) = N'{"position":{"x":1,"y":2,"z":3}, "latency":32, "health": 347, "magic":142, "bag": {"coins": 5, "dagger":1}, "state": {"quests":{"finished": [1,2,5,7,12,43], "open": [3,4,10], "active": 3} } }';
exec api.[put_player_data] @id = @id, @payload =  @p;
go

declare @p as nvarchar(max) = N'{"position":{"x":2,"y":42,"z":34}, "latency":32, "health": 347, "magic":142, "bag": {"coins": 5, "dagger":1}, "state": {"quests":{"finished": [1,2,5,7,12,43], "open": [3,4,10], "active": 3} } }';
exec api.[put_player_data] @id = '69201DAB-70F8-48DB-9D0B-9A261EC73E1B', @payload =  @p;
go

exec api.[get_player_data] '69201DAB-70F8-48DB-9D0B-9A261EC73E1B'
go

select * from api.player_state