USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[single_legal_bussiness]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE  [dbo].[single_legal_bussiness]
 @bussiness varchar(10)
AS
Begin 
 exec 	 pro_e1_single_leg_reward  @bussiness
 exec    pro_e2_single_redemption  @bussiness
   exec [dbo].[pro_e3_single_coupon]  @bussiness
END


GO
