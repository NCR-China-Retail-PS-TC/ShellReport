USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[CrossJV_Member]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Ryan Liang
-- Create date: 2019.8.1
-- Description:	Create Cross JV Member (会籍转移)
-- =============================================
--declare @MatrixMemberId int = 4, @BussinessDate datetime = '2017/12/21'
/*
	exec CrossJV_Member 4, '2019/12/9'
	select * from CrossJVTemp_Member
*/
CREATE procedure [dbo].[CrossJV_Member]
(	
    @MatrixMemberId int, 
    @UpdatedDate  datetime
)
as
    begin
        set nocount on;
        if object_Id('dbo.CrossJVTemp_Member', 'U') is not null
            drop table dbo.CrossJVTemp_Member;

        declare @ParmDefinition nvarchar(max)= N'@MatrixMemberId int, @UpdatedDate date';
        declare @sql nvarchar(max) = N'
	
	if OBJECT_ID(''tempdb..#toJV'') is not null
        drop table #toJV;

    select v.MatrixMemberId, c.JVCN, v.SegmentId, v.SegmentDescription, v.SegmentInternalKey, 
	       l.ClubCardId, l.Action, l.MemberInternalKey, l.UpdateDate
	  into #toJV
	   from v_cs_segment as v
	   join #Loyalty#..CRM_MemberSegment_Log as l on l.SegmentInternalKey = v.SegmentInternalKey
	   join CrossJVConfig as c on c.MatrixMemberId = v.MatrixMemberId
	  where cast(l.UpdateDate as date) = @UpdatedDate
	    and l.Action = 1

	 if OBJECT_ID(''tempdb..#fromJV'') is not null
        drop table #fromJV;

	 select v.MatrixMemberId, c.JVCN, v.SegmentId, v.SegmentDescription, v.SegmentInternalKey, 
	        l.ClubCardId, l.Action, l.MemberInternalKey, l.UpdateDate
	   into #fromJV
	   from v_cs_segment as v
	   join #Loyalty#..CRM_MemberSegment_Log as l on l.SegmentInternalKey = v.SegmentInternalKey
	   join CrossJVConfig as c on c.MatrixMemberId = v.MatrixMemberId
	  where cast(l.UpdateDate as date) = @UpdatedDate
		and exists (select 1 
		                  from #toJV
						 where MemberInternalKey = l.MemberInternalKey
						   and SegmentInternalKey != l.SegmentInternalKey)
	    and l.Action = 2';

	set @sql = @sql + N'
   select fromJV.JVCN as fromJV,
          fromJV.SegmentDescription as fromArea,
          gs.storeid as fromStoreId,
          gs.storename as fromStoreName,
          toJV.JVCN as toJV,
          toJV.SegmentDescription as toArea,
          toJV.ClubCardId,
          toJV.UpdateDate,
		  isnull((
			  select top 1 balance from (
				  select sum(EarnValue + RedeemValue) over (order by PosTranInternalKey) as balance, MatrixMemberId
				  from #Loyalty#..CRM_POSAccountsActivity 
				  where BuyingUnitInternalKey = m.BuyingUnitInternalKey
			  ) as t 
			  where t.MatrixMemberId = fromJV.MatrixMemberId
		  ),0) as balance
	 into CrossJVTemp_Member
     from #toJV as toJV
     join #fromJV as fromJV on toJV.MemberInternalKey = fromJV.MemberInternalKey
     join #Loyalty#..CRM_Member (nolock) as m on m.MemberInternalKey = toJV.MemberInternalKey
	 join report_data..v_get_reg_compAndStore as gs on gs.MemberInternalKey = toJV.MemberInternalKey
    where toJV.MatrixMemberId != fromJV.MatrixMemberId
      and (fromJV.MatrixMemberId = @MatrixMemberId or toJV.MatrixMemberId = @MatrixMemberId);';
      
		declare @_sql nvarchar(max);
		exec ReplaceSQL @sql, @UpdatedDate, @_sql output;

        execute sp_executesql 
                @_sql,
                @ParmDefinition,
                @MatrixMemberId = @MatrixMemberId,
				@UpdatedDate = @UpdatedDate;

		update CrossJVTemp_Member set ClubCardId = ''''+ ClubCardId;
    end;


GO
