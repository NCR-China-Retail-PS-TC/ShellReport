USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[main_est_auto_hb]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	CALL THE EST  TO CREATE THE  report  for finicance 
--  财务报表主程序,调用财务报表及新会员采用拉链技术生成 =================
CREATE    PROCEDURE [dbo].[main_est_auto_hb] 
AS
  BEGIN
     
      DECLARE @dataDate VARCHAR(10)
	   set @dataDate= convert( varchar(10),getdate()-1,120)
       exec [dbo].[main_est_manual_hb] @dataDate
  END 

GO
