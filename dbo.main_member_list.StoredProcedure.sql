USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[main_member_list]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:  call the member_list to extract the club infomation at 0:05am every day  =================
CREATE  PROCEDURE  [dbo].[main_member_list]
	-- 
AS
BEGIN
  declare  @dataDate varchar(20);
  declare   @dataDateEnd varchar(20);
  set @dataDate=convert(varchar(10),dateadd(day,-1,getdate()),120);
 set @dataDateEnd=convert(varchar(10),getdate()+1,120);

   exec dbo.member_list @dataDate,@dataDateEnd
 --20170615 16:54  stop execute this procedure.
END


GO
