USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[main_interface_etl_manual]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
 CREATE  PROCEDURE [dbo].[main_interface_etl_manual]
   @bussiness_date VARCHAR(10)
	AS
BEGIN

exec [dbo].[erp_ds] @bussiness_date
exec [dbo].[pointConvertCoupon] @bussiness_date ,1
 exec	[dbo].[pro_e1_single_leg_reward]  @bussiness_date  --单法律实体积分发放
  exec  [dbo].[pro_e2_single_redemption] @bussiness_date    --单法律实体积分兑换
  exec  [dbo].[pro_e4_mult_reward] @bussiness_date          --多法律实体积分发放
  exec  [dbo].[pro_e5_mult_redemption] @bussiness_date      --多法律实体积分兑换
exec   [dbo].[pro_e7_point_expired] @bussiness_date       --积分到期统计,需要先运行积分兑换程序 [dbo].[member_point_redem]
  EXEC [dbo].[Pro_e3_single_coupon] @bussiness_date  
END


 


GO
