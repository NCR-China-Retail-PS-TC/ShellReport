USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[main_est_auto]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE  [dbo].[main_est_auto] 
as
declare @date varchar(10)
set @date=convert(varchar(10),getdate()-1,120)

exec [dbo].[main_est_manual_sx]  @date
exec [dbo].[main_est_manual_hb]  @date
exec [dbo].[main_est_manual_sc]  @date
exec [dbo].[main_est_manual]  @date,6
exec [dbo].[main_est_manual]  @date,7
exec [dbo].[main_est_manual]  @date,8
exec [dbo].[main_est_manual]  @date,9
GO
