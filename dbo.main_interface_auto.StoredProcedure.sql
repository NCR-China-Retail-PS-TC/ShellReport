USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[main_interface_auto]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE  [dbo].[main_interface_auto] 
as
declare @date varchar(10),@BeginTime datetime=getdate();

set @date=convert(varchar(10),getdate()-1,120)

exec [dbo].[main_interface_etl_sx]  @date
exec [dbo].[main_interface_etl_hb]  @date
 exec  [dbo].[main_interface_etl_sc]   @date
delete  DataETLInfo  where dusinessDate=@date  and RetailerId=0
insert into  DataETLInfo  (RetailerId,DusinessDate,ETLFinished,ETLFinishedTime,ETLBeginTime,TransMark)
values('0',@date,'OK',GETDATE(),@BeginTime,'wait')
GO
