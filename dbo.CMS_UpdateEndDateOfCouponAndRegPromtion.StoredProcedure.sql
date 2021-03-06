USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[CMS_UpdateEndDateOfCouponAndRegPromtion]    Script Date: 1/19/2022 9:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* =============================================
6.2.	修改会员账户下的优惠券、注册促销的结束日期
	参数：会员卡号(loyaltyID)、Retail ID、类型（1：优惠券，2：注册促销），券号（优惠券）/促销ID（注册促销）、更新的结束日期（注意判断更新的结束日期不能晚于促销的结束日期）

	返回值：更新结果（成功、失败）。
接口需要检查更新的结束日期，如果更新的结束日期晚于促销的结束日期，则券的结束日期更新为与促销相同的结束日期
-- Author:		<Author,,Name>
-- Create date: 2020-09-13
-- Description:	<Description,,>
-- =============================================
*/
create  PROCEDURE [dbo].[CMS_UpdateEndDateOfCouponAndRegPromtion] 
	@ClubCardId nvarchar(50),
	@RetailId  nvarchar(10),
	@type  int,
	@NumberId nvarchar(50),
	@EndDate varchar(10),
	@JSON  NVARCHAR(MAX) output
	AS
BEGIN
  if @type=1 
  begin 
   declare @upDate nvarchar(10)

   
 

  update  cld set  cld.EndDate= case when  @EndDate>ph.PromotionHeaderEndDate then PromotionHeaderEndDate
   else  @EndDate   end
       from  Loyalty_Shell_uat..CRM_LoyaltyDocuments  cld
  inner join  report_data..RetailCode_MP rc on cld.MatrixMemberId=rc.MatrixMemberId
  inner join Loyalty_Shell_uat..CRM_BuyingUnit cbu on cbu.BuyingUnitInternalKey=cld.IssuedBuyingUnitInternalKey and cbu.MatrixMemberId=cld.MatrixMemberId
  left join Loyalty_Shell_uat..PromotionHeader_PR ph on cld.PromotionHeaderId=ph.PromotionHeaderId and cld.MatrixMemberId=ph.MatrixMemberId
  where cld.Barcode=@NumberId and cbu.ExternalBuyingUnit=@ClubCardId

   select  @update= convert(varchar(10), cld.EndDate,120)
          from  Loyalty_Shell_uat..CRM_LoyaltyDocuments  cld
  inner join  report_data..RetailCode_MP rc on cld.MatrixMemberId=rc.MatrixMemberId
  inner join Loyalty_Shell_uat..CRM_BuyingUnit cbu on cbu.BuyingUnitInternalKey=cld.IssuedBuyingUnitInternalKey and cbu.MatrixMemberId=cld.MatrixMemberId
  left join Loyalty_Shell_uat..PromotionHeader_PR ph on cld.PromotionHeaderId=ph.PromotionHeaderId and cld.MatrixMemberId=ph.MatrixMemberId
  where cld.Barcode=@NumberId and cbu.ExternalBuyingUnit=@ClubCardId

   if @@ROWCOUNT=0 
   set @json='{"result":"0","date":""}'
   else 
   set @json='{"result":"1","date":"'+@upDate+'"}'
  end

  if @type=2
  begin 
 
  update  cbup set  cbup.RegistrationEndDate=  case when  @EndDate>ph.PromotionHeaderEndDate then PromotionHeaderEndDate
   else  @EndDate   end
       from  Loyalty_Shell_uat..CRM_BuyingUnitPromotion  cbup
  inner join  report_data..RetailCode_MP rc on cbup.MatrixMemberId=rc.MatrixMemberId
  inner join Loyalty_Shell_uat..CRM_BuyingUnit cbu on cbu.BuyingUnitInternalKey=cbup.BuyingUnitInternalKey and cbu.MatrixMemberId=cbup.MatrixMemberId
  left join Loyalty_Shell_uat..PromotionHeader_PR ph on cbup.PromotionHeaderId=ph.PromotionHeaderId and cbup.MatrixMemberId=ph.MatrixMemberId
  where cbup.PromotionHeaderId=@NumberId and cbu.ExternalBuyingUnit=@ClubCardId
 
  select  @upDate=  convert(varchar(10),cbup.RegistrationEndDate,120)
       from  Loyalty_Shell_uat..CRM_BuyingUnitPromotion  cbup
  inner join  report_data..RetailCode_MP rc on cbup.MatrixMemberId=rc.MatrixMemberId
  inner join Loyalty_Shell_uat..CRM_BuyingUnit cbu on cbu.BuyingUnitInternalKey=cbup.BuyingUnitInternalKey and cbu.MatrixMemberId=cbup.MatrixMemberId
  left join Loyalty_Shell_uat..PromotionHeader_PR ph on cbup.PromotionHeaderId=ph.PromotionHeaderId and cbup.MatrixMemberId=ph.MatrixMemberId
  where cbup.PromotionHeaderId=@NumberId and cbu.ExternalBuyingUnit=@ClubCardId
  
 
  if @@ROWCOUNT=0 
   set @json='{"result":"0","date":""}'
   else 
   set @json='{"result":"1","date":"'+@upDate+'"}'
  end
  print @json


END
GO
