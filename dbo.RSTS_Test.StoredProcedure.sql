USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[RSTS_Test]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





-- =============================================
-- Author:		Ryan Liang
-- Create date: 2019.10.3
-- Description:	[CR] RSTS, Export csv to Shell SAP
-- Version:     0.0.2
-- =============================================

/**** Run **** 
use report_data
Exec RSTS 1,'2020/3/23'
Exec RSTS 4,'2020/3/12'
**** Run ****/

CREATE PROCEDURE [dbo].[RSTS_Test]
	@MatrixMemberId as int,
	@TranDate as date
AS
--declare @MatrixMemberId int = 2, @TranDate date = '2019/7/17'

declare @countryCode char(2) = case 
									when @MatrixMemberId = 1 then 'A1'  --HB
									when @MatrixMemberId = 4 then 'A2'  --SX
									when @MatrixMemberId = 5 then 'A3'  --SC
									when @MatrixMemberId = 6 then 'A4'  --WOFE
									when @MatrixMemberId = 7 then 'A5'  --FJ
									when @MatrixMemberId = 8 then 'A6'  --Crown
								else 'A0' end;
declare	@filename varchar(100) = @countryCode + '_' + convert(varchar, getdate(), 112) + '_' + replace(convert(varchar, getdate(), 108), ':', '') +'_RSTS.CSV';
declare @sql nvarchar(max);
BEGIN
	  SET NOCOUNT ON;

	  IF OBJECT_ID('tempdb.dbo.##RSTS', 'U') IS NOT NULL
		  DROP TABLE ##RSTS 

	  Create Table ##RSTS(RowID int, TicketInternalKey int, LineId int, ExportOrder int, Content nvarchar(max))
  
	  /* Item */
	  set @sql= N'
	  insert into ##RSTS (RowID, TicketInternalKey, LineId, ExportOrder, Content)
	  select 0, b.TicketInternalKey, c.LineId, 1,
		     ''I¦'' + @countryCode + ''¦'' + a.StoreId + ''¦¦'' + cast(b.TranId as varchar) + ''¦'' + 
		     convert(varchar, b.StartDateTime, 112) + ''¦'' + replace(convert(varchar, b.StartDateTime, 108), '':'', '''') + ''¦'' +
		     cast(a.CashierId as varchar) + ''¦'' + cast(a.TillId as varchar) + ''¦'' + cast(c.LineId as varchar) + ''¦'' + d.MainItemId + 
		     ''¦¦'' + --EAN
		     d.midtypeCode + ''¦'' + e.id + ''¦'' + e.id + ''¦'' + --<= Legacy Category
		     cast((c.Amount - isnull(g.RewardValue, 0)) as varchar) + ''¦0¦¦'' + --<= Tax, Tax Rate
		     case when d.ItemType = ''0'' then ''L'' else ''EA'' end + ''¦'' + cast(c.Price as varchar) + ''¦'' + cast(c.Qty as varchar) + ''¦'' + 
		     d.FullName + ''¦'' + case when d.ItemType = ''0'' then ''F'' else ''N'' end  + ''¦CNY¦'' + case when g.RewardValue is null then ''N'' else ''Y'' end
		from #ATD#..FO_TranCollection (nolock) as a
		join #ATD#..FO_TranHeader#YYYYMM# (nolock) as b on a.CollectionInternalKey = b.CollectionInternalKey
		join (
			select ROW_NUMBER() over(partition by TicketInternalKey order by ItemId) as LineId, TicketInternalKey, ItemId, max(Price) as Price, sum(Qty) as Qty, sum(Amount) as Amount
			  from #ATD#..FO_TranSale#YYYYMM# (nolock) as c
		  group by TicketInternalKey, ItemId 
		) as c on c.TicketInternalKey = b.TicketInternalKey
		left join (
			select TicketInternalKey, EntityId, sum(RewardValue) as RewardValue
			  from #ATD#..FO_TranPromotionRewardApportionment#YYYYMM# (nolock)
			 where RewardMethodId = 4
		  group by TicketInternalKey, EntityId
		) as g on g.TicketInternalKey = c.TicketInternalKey and g.EntityId = c.ItemId
		join report_data..item_cat (nolock) as d on d.MatrixMemberId = @MatrixMemberId and d.MainItemId = c.ItemId
		join #MP#..ItemHierarchyTemplateLine_ALL (nolock) as e on e.MatrixMemberId = @MatrixMemberId and e.CategoryKey = d.CategoryKey
		join #HOST#..RetailerCode (nolock) as r on r.RetailerId = a.RetailerId
		where cast(b.StartDateTime as date) = @TranDate
	    and r.MatrixMemberId = @MatrixMemberId
	';

	/* Paymemt */
	set @sql=@sql + '
	  insert into ##RSTS (RowID, TicketInternalKey, LineId, ExportOrder, Content)
	  select 0, b.TicketInternalKey, f.LineId, 2,
		     ''P¦'' + @countryCode + ''¦'' + a.StoreId + ''¦'' + cast(b.TranId as varchar) + ''¦'' + 
		     convert(varchar, b.StartDateTime, 112) + ''¦'' + replace(convert(varchar, b.StartDateTime, 108), '':'', '''') + ''¦'' +
		     cast(f.StoreTenderId as varchar) + ''¦'' + cast(f.StoreTenderId as varchar) + ''¦'' + isnull(g.TenderName, '''') + ''¦'' + cast(f.Amount as varchar)  + ''¦CNY¦''
		from #ATD#..FO_TranCollection (nolock) as a
		join #ATD#..FO_TranHeader#YYYYMM# (nolock) as b on a.CollectionInternalKey = b.CollectionInternalKey
   left join #ATD#..FO_TranTender#YYYYMM# (nolock) as f on f.TicketInternalKey = b.TicketInternalKey
   left join #HOST#..Tender (nolock) as g on g.MatrixMemberId = @MatrixMemberId and g.TenderId = f.StoreTenderId
		join #HOST#..RetailerCode (nolock) as r on r.RetailerId = a.RetailerId
		where cast(b.StartDateTime as date) = @TranDate
	    and r.MatrixMemberId = @MatrixMemberId
	  ';

	 /* Loyalty */
	 set @sql=@sql + '
	 insert into ##RSTS (RowID, TicketInternalKey, LineId, ExportOrder, Content)
	 select 0, b.TicketInternalKey, 0, 3, 
	        ''L¦'' + @countryCode + ''¦'' + a.StoreId + ''¦'' + cast(b.TranId as varchar) + ''¦'' + 
		     convert(varchar, b.StartDateTime, 112) + ''¦'' + replace(convert(varchar, b.StartDateTime, 108), '':'', '''') + ''¦'' + 
			 f.CardId + ''¦¦'' + cast(g.RewardValue as varchar)
		from #ATD#..FO_TranCollection (nolock) as a
		join #ATD#..FO_TranHeader#YYYYMM# (nolock) as b on a.CollectionInternalKey = b.CollectionInternalKey
		join #ATD#..FO_TranCard#YYYYMM# (nolock) as f on f.TicketInternalKey = b.TicketInternalKey
		join (
			select TicketInternalKey, sum(RewardValue) as RewardValue
				from #ATD#..FO_TranPromotionRewardApportionment#YYYYMM# (nolock)
				where RewardMethodId = 1
				and RewardId = 100
				group by TicketInternalKey
		) as g on g.TicketInternalKey = b.TicketInternalKey
		join #HOST#..RetailerCode (nolock) as r on r.RetailerId = a.RetailerId
		where cast(b.StartDateTime as date) = @TranDate
	    and r.MatrixMemberId = @MatrixMemberId
		'

	  /* Discount */
	  set @sql=@sql + '
	  insert into ##RSTS (RowID, TicketInternalKey, LineId, ExportOrder, Content)
	  select 0, b.TicketInternalKey, c.LineId, 4,
			 ''D¦'' + @countryCode + ''¦'' + a.StoreId + ''¦'' + cast(b.TranId as varchar) + ''¦'' + 
		     convert(varchar, b.StartDateTime, 112) + ''¦'' + replace(convert(varchar, b.StartDateTime, 108), '':'', '''') + ''¦'' +
			 cast(c.LineId as varchar) + ''¦'' + cast(h.PromotionId as varchar) + ''¦'' + cast(i.PromotionTypeId as varchar) + ''¦'' + cast(h.RewardValue as varchar) + ''¦0¦0¦CNY''
		from #ATD#..FO_TranCollection (nolock) as a
		join #ATD#..FO_TranHeader#YYYYMM# (nolock) as b on a.CollectionInternalKey = b.CollectionInternalKey
		join (
			select ROW_NUMBER() over(partition by TicketInternalKey order by  ItemId) as LineId, TicketInternalKey, ItemId, sum(Price) as Price, sum(Qty) as Qty, sum(Amount) as Amount
			  from #ATD#..FO_TranSale#YYYYMM# (nolock) as c
		  group by TicketInternalKey, ItemId 
		) as c on c.TicketInternalKey = b.TicketInternalKey
		join (
			select TicketInternalKey, EntityId, sum(RewardValue) as RewardValue
			  from #ATD#..FO_TranPromotionRewardApportionment#YYYYMM# (nolock)
			 where RewardMethodId = 4
		  group by TicketInternalKey, EntityId
		) as g on g.TicketInternalKey = c.TicketInternalKey and g.EntityId = c.ItemId
		left join #ATD#..FO_TranPromotionRewardApportionment#YYYYMM# (nolock) as h on h.TicketInternalKey = b.TicketInternalKey and h.EntityId = g.EntityId and RewardMethodId = 4
		join #Promotion#..promotionheader (nolock) as i on i.MatrixMemberId = @MatrixMemberId and i.PromotionHeaderId = h.PromotionId
		join #HOST#..RetailerCode (nolock) as r on r.RetailerId = a.RetailerId
		where cast(b.StartDateTime as date) = @TranDate
	    and r.MatrixMemberId = @MatrixMemberId
	';

	/* Replace */
	declare @_sql nvarchar(max);
	exec ReplaceSQL @sql, @TranDate, @_sql output;

		select @_sql

	declare @ParmDefinition nvarchar(max)= N'@MatrixMemberId int, @TranDate date, @countryCode char(2)';
	execute sp_executesql @_sql, @ParmDefinition, @MatrixMemberId = @MatrixMemberId, @TranDate = @TranDate, @countryCode = @countryCode;

	/* export */
	insert into ##RSTS (RowID, TicketInternalKey, ExportOrder, Content)
	select -1, -1, -1, 'H¦' + cast(count(1) as varchar)
	  from ##RSTS

	declare @cmd varchar(1000) = 'bcp "select content from ##RSTS order by RowID, TicketInternalKey, ExportOrder, LineId" queryout "E:\FN_Extract_Data\RSTS\' + @filename + '"   -c -C65001   -T -t"¦"'
	
	exec sys.xp_cmdshell @cmd

	--exec sys.xp_cmdshell 'powershell -noprofile -command "&{ start-process powershell -ArgumentList ''-noprofile -file d:\FN_Extract_Data\RSTS\temp\reFormat.ps1'' -verb RunAs}"'

	--select * from ##RSTS 
	--where TicketInternalKey = 28453
	--order by RowID,TicketInternalKey,ExportOrder, LineId
	drop table ##RSTS
END


GO
