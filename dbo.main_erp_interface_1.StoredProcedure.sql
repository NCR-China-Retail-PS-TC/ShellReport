USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[main_erp_interface_1]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[main_erp_interface_1]
 @business_date varchar(10)
AS

BEGIN
   
  
  set @business_date =CONVERT(varchar(10),getdate(),120);

   exec  [erp_ds] '2017-05-18','2017-05-20'

  exec  [pro_e1_single_leg_reward] '2017-05-18'
  exec   [pro_e2_single_redemption] '2017-05-18'
END
GO
