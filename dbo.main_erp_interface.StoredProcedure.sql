USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[main_erp_interface]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:接口报表数据主程序，在自动提取数据中调用该过程 
-- =================
CREATE PROCEDURE [dbo].[main_erp_interface]
AS
  BEGIN
      DECLARE @dataDate VARCHAR(20);
      DECLARE @dataDateEnd VARCHAR(20);
      DECLARE @day VARCHAR(2)
      SET @day=Substring(CONVERT(VARCHAR(10), Getdate(), 120), 9, 2);
      IF @day = '02'
        RETURN
      ELSE
        BEGIN
            IF @day = '01' --  1号执行前两天的批处理  
            begin   SET @dataDate=CONVERT(VARCHAR(10), Dateadd(day, -1, Getdate()), 120);
            EXEC [Erp_ds] @dataDate
			exec [dbo].[pointConvertCoupon] @dataDate,1
            EXEC [Pro_e1_single_leg_reward] @dataDate
            EXEC [Pro_e2_single_redemption] @dataDate
            EXEC [dbo].[Pro_e4_mult_reward] @dataDate
            EXEC [dbo].[Pro_e5_mult_redemption] @dataDate
            EXEC [dbo].[Pro_e3_single_coupon] @dataDate
			 exec   [dbo].[pro_e7_point_expired] @dataDate
			end;
		    --  if @day<>'02'
              SET @dataDate=CONVERT(VARCHAR(10), Dateadd(day, -2, Getdate()), 120);
         
            EXEC [Erp_ds] @dataDate
			exec [dbo].[pointConvertCoupon] @dataDate,1
            EXEC [Pro_e1_single_leg_reward] @dataDate
            EXEC [Pro_e2_single_redemption] @dataDate
            EXEC [dbo].[Pro_e4_mult_reward] @dataDate
            EXEC [dbo].[Pro_e5_mult_redemption] @dataDate
            EXEC [dbo].[Pro_e3_single_coupon] @dataDate

           
        END
  END 

GO
