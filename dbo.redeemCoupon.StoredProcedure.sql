USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[redeemCoupon]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE  [dbo].[redeemCoupon]
	
AS
BEGIN
--获取优惠券发行信息, 
--在CRM_LoyaltyDocuments 存放优惠卷信息status 中0=Active, 1=Redeem, 2=Cancel,
--FO_TranPromotionRedemption201706存放交易是发卷还是折扣;
--[ATD_Shell].[dbo].[FO_TranPromotionIssuedDocument201706] 存放交易用劵,发劵信息.
--RewardMethodId 3 是发劵,4用劵
 select  ftpr.*,cld.IssueStoreInternalKey ,fth.*
   from       [ATD_Shell].[dbo].[FO_TranPromotionRedemption201706]  ftpr
           --rewardmethodid (1-MemberAccount,2-Voucher,3-Coupon,4-Discount,5-MOP,6-Target Message,8=Decrease Member Account)
 inner join  [ATD_Shell].[dbo].[FO_TranPromotionIssuedDocument201706] ftpid on ftpid.TicketInternalKey=ftpr.TicketInternalKey
 inner join  [Loyalty_Shell_1].[dbo].[CRM_LoyaltyDocuments] cld on ftpid.DocumentId=cld.Barcode 
 inner join  ATD_Shell.dbo.FO_TranHeader201706  fth on fth.TicketInternalKey=ftpr.TicketInternalKey
 inner join  ATD_Shell.dbo.FO_TranCollection  ftc on ftc.CollectionInternalKey=fth.CollectionInternalKey
  where   ftc.BusinessDate='2017-06-12' and ftpr.RewardMethodId=4  --and fth.TicketInternalKey=5081
  and cld.Status=0 -- -- 0=Active, 1=Redeem, 2=Cancel
END












GO
