USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[proc__coupon]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	优惠券使用
-- =============================================
create PROCEDURE   [dbo].[proc__coupon]
 @business_date varchar(10)    --营业日期	
AS
BEGIN
   --插入优惠券使用数据


 insert  into   [report_data].[dbo].[DS_R3_coupon_use]
 (     [member_card_no]          --1
      ,[member_reg_comp_code]    --2
      ,[member_reg_comp]         --3
      ,[member_reg_store_code]   --4
      ,[member_reg_store]        --5
      ,[legal_code]              --6
      ,[legal_name]              --7
      ,[store_code]              --8
      ,[store_name]              --9
      ,[city]                    --10
    /*  ,[cashierid]              
      ,[transaction_no]
      ,[business_date]
      ,[transaction_date]
      ,[transaction_time]
      ,[posid]  */
      ,[item_cat]				--11
      ,[item_cat_mid_code]      --12 
      ,[item_cat_mid]           --13
      ,[item_code]              --14
      ,[item_name]              --15
      ,[reward_amount]          --16 
     /* ,[promtion_id]            --17 
      ,[promtion_group]    
      ,[promtion_ref]    */
      ,[create_date]				--17
	  )

 select  reggs.compID  as regcompid		--1
      ,reggs.comp      as regcomp		--2
      ,reggs.[storeid]  as regstoreid	--3
      ,reggs.storename   as regstorename --4
      ,gs.compID						--5
	  ,gs.comp							--6
	  ,gs.storeid						--7
	  ,gs.storename						--8
	   ,gs.city							--9	
	  ,ftc.BusinessDate					--10
	  ,item.MainItemId					--11
	  ,item.FullName					--12
	  ,item.midtypeCode					--13
	  ,item.firsttypeCode				--14
	  ,item.firsttype					--15
	  ,ftpra.RewardValue				--16
	  ,	fth.CreatedDate					--17  
	  from        ATD_Shell.[dbo].[FO_TranPromotionRewardApportionment201706]  ftpra 
   inner join   [ATD_Shell].[dbo].[FO_TranPromotionRedemption201706]  ftpr
    on ftpra.TicketInternalKey=ftpr.TicketInternalKey  and ftpr.RewardMethodId=4  and ftpra.RewardMethodId=4
	  and ftpr.TriggerCouponQty>0
 inner join  [ATD_Shell].[dbo].[FO_TranPromotionIssuedDocument201706] ftpid on ftpid.TicketInternalKey=ftpra.TicketInternalKey
 inner join  [Loyalty_Shell_1].[dbo].[CRM_LoyaltyDocuments] cld on ftpid.DocumentId=cld.Barcode 
 left join ATD_Shell.dbo.FO_TranHeader201706 fth on fth.TicketInternalKey=ftpr.TicketInternalKey
 left join ATD_Shell.dbo.[FO_TranCollection] ftc on fth.CollectionInternalKey=ftc.CollectionInternalKey
 left join store_gs  gs on gs.storeid=ftc.StoreId
 left join [dbo].[member_gs]  reggs on cld.IssuedBuyingUnitInternalKey=reggs.BuyingUnitInternalKey
 left join item_cat item on item.MainItemId=ftpra.EntityId
  where  ftpr.triggerCouponqty>0 and ftc.BusinessDate=convert(date,@business_date,120)
  

  
  
   
END


GO
