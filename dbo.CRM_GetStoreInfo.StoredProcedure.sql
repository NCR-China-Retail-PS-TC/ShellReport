USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[CRM_GetStoreInfo]    Script Date: 1/19/2022 9:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create  PROCEDURE  [dbo].[CRM_GetStoreInfo]  
	@retailerId varchar(1)
	,@json  nvarchar(max) output
AS
BEGIN
declare @sql nvarchar(max);
 set @sql='	select   rid.RetailerId,  storeid, storename, 
   comp,compID, StoreIsActive,StoreType
   from report_data..store_gs  s
	left join [dbo].[RetailCode_MP] Rid  on s.MatrixMemberId=rid.MatrixMemberId
	where rid.RetailerId    like '''+ @retailerId+'%'''


EXEC report_data..[SerializeJSON]   @sql,@json output
set @json=N'{"StoreInfo":'+@json+N'}'
 print @json
end
GO
