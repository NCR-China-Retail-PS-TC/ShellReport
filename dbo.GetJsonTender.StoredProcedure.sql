USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[GetJsonTender]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
  --declare @json varchar(max) 
 -- exec  GetJsonTender '1',@json output
--  print @json
-- =============================================
create   PROCEDURE  [dbo].[GetJsonTender]  
	@retailerId varchar(1)
	,@json  nvarchar(max) output
AS
BEGIN
declare @sql nvarchar(max);
 set @sql='	SELECT t.TenderId,t.TenderName,r.RetailerId 
  FROM [ATD_Shell].[dbo].[Tender_ALL] t
  left join report_data..RetailCode_MP r on t.MatrixMemberId =r.MatrixMemberId
  where   retailerId<>0 and    r.RetailerId like '''+ @retailerId+'%'''


EXEC report_data..[SerializeJSON]   @sql,@json output
set @json=N'{"TenderInfo":'+@json+N'}'
 print @json



	

END

GO
