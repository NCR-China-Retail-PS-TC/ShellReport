USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[Get_MemberConsumeInfo]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



/*
那些关于你的2020年加油瞬间
都深深铭记在小油滴心中
那些瞬间，你是否还记得？
declare @clardId nvarchar(50)='7004900058685973910'
,@json nvarchar(500)
exec Get_MemberConsumeInfo @clardId ,@json  output

*/
CREATE  PROCEDURE   [dbo].[Get_MemberConsumeInfo]
	@ClubCardId  nvarchar(50)='7004900089894650910'
		,@json nvarchar(max)  output
AS

set transaction isolation  level read uncommitted;
declare @sql1 varchar(max)
,@sql varchar(max)
 set @sql1='	

    select             [ClubCardId]    as [ClubCardId]
           , isnull（ [RegDate]     ,'''+''''+'）  as [RegDate]
           , isnull（ [RetailerId]  ,'''+''''+'）  as [RetailerId]
           , isnull（ [RetailerName],'''+''''+'）   as [RetailerName]
           , isnull（ [JVCode]      ,'''+''''+'）   as [JVCode]
           , isnull（ [JVCodeName]  ,'''+''''+'）   as [JVCodeName]
           , isnull（ [FirstDateTime],'''+''''+'）  as [FirstDateTime]
           , isnull（ [FirstStoreCode],'''+''''+'）  as [FirstStoreCode]
           , isnull（ [FistStoreName], '''+''''+'）    as [FistStoreName]
           , isnull（ [FirstStoreTransTimes],'''+''''+'）  as [FirstStoreTransTimes]
           ,  isnull（ [LastDatetime],'''+''''+'）         as [LastDatetime]
           , isnull（ [NFRQTY]      ,0）          as [NFRQTY]
           , isnull（ [NFRAmount]   ,0）          as [NFRAmount]
           , isnull（ [FRTimes]     ,0）         as [FRTimes]
           , isnull（ [FRQty]       ,0）         as [FRQty]
           , isnull（ [discount]    ,0）          as [discount]
           , isnull（ [transTimes]  ,0）          as [transTimes]
           , isnull（ [totalConsume],0）          as [totalConsume]
           , isnull（ [orderNumber] ,0）          as [orderNumber]
           , isnull（ [OrderPercent],0）          as [OrderPercent]
		   from CRM_MemberConsumeInfo_tmp cmc1
where    cmc1.ClubCardId='''+@ClubCardId+''''

set @sql='select [ClubCardId]
           ,[RegDate]
           ,[RetailerId]
           ,[RetailerName]
           ,[JVCode]
           ,[JVCodeName]
           ,[FirstDateTime]
           ,[FirstStoreCode]
           ,[FistStoreName]
           ,[FirstStoreTransTimes]
            ,[LastDatetime]
           ,[NFRQTY]
           ,[NFRAmount]
           ,[FRTimes]
           ,[FRQty]
           ,[discount]
           ,[transTimes]
           ,[totalConsume]
           ,[orderNumber]
           ,[OrderPercent]

 --- from  CRM_MemberConsumeInfo cmc1 
 from CRM_MemberConsumeInfo cmc1
where    cmc1.ClubCardId='''+@ClubCardId+''''

print @sql1
EXEC report_data..[SerializeJSON]   @sql1,@json output
set @json=N'{"CRM_MemberConsumeInfo_t":'+@json+N'}'
 print @json

 
        

GO
