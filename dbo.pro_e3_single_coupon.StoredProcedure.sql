USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[pro_e3_single_coupon]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	优惠券使用
-- =============================================
create PROCEDURE   [dbo].[pro_e3_single_coupon]
 @business_date varchar(10)='2017-07-27'	
AS
BEGIN
  declare    @MatrixMemberId  varchar(1)='1';
   --插入优惠券使用数据
   
/*
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
  where  ftpr.triggerCouponqty>0 and ftc.BusinessDate=convert(date,'2017-06-15',120)
  
  */
  --插入折扣数据

  	update      [e3_single_coupon]  set fb_state='9'
	   where    [business_date]=@business_date
	       and  fb_state in ('0','E');
  insert  into   [report_data].[dbo].[e3_single_coupon]
      (  /*   [member_reg_comp_code]  --1
           ,[member_reg_store_code]   --2
           ,[member_reg_store]        --3  */
            [store_code]			  --4
           ,[store_name]			--5
           ,[legal_code]			--6
           ,[legal_name]			--7
           ,[city]					--8
           ,[business_date]			--9
           ,[etl_date]				--10
           ,[etl_time]				--11
           ,[point_type]			--12
           ,[commodity_type]		--13
           ,[commodity_name]		--14
           ,[point_amount]			--15
           ,[point_service_type]	--16
           ,[business_name]			--17
           ,[id]					--18
           ,[fb_state]				--19
               )
	  select /*drtd.member_reg_comp_code		--1
	        ,drtd.member_reg_store_code		--2
			,drtd.member_reg_store			--3 */
			drtd.store_code				--4
			,drtd.store_name				--5
			,drtd.legal_code				--6
			,drtd.legal_name				--7
			,drtd.city						--8
			,drtd.business_date				--9
			,convert(varchar(10),getdate(),120)  --10
            ,convert(varchar(12),getdate(),114)   --11
	        ,'J09'      --公司发行优惠券 C促销折扣--12
			, case when   ic.firsttypeCode='10' then drtd.item_code
	                      else drtd.item_cat_mid_cod
	          end                               --13
           ,   case when   ic.firsttypeCode='10' then drtd.item_name
	              else drtd.item_cat_mid
		    	end                                --14
				,sum(drtd.discount_amount)        --15
				,'J0303'   --公司发行有效期优惠券   -16
				,N'公司发行有效期优惠券'			--17 
				, 'J0303'+drtd.store_code+drtd.business_date+ case when   IC.firsttypeCode='10' then drtd.item_code
	                 else drtd.item_cat_mid_cod 
	             end  id                       --18
			,'0'   fb_state						--19 	                 
	    from DS_R1_1_tran_discount drtd
		left join  item_cat  ic on drtd.item_code=ic.MainItemid
		 and ic.MatrixMemberId=@MatrixMemberId
   where drtd.business_date=@business_date and
	   'J0303'+drtd.store_code+drtd.business_date+ case when   IC.firsttypeCode='10' then drtd.item_code
	                 else drtd.item_cat_mid_cod end
					   not in (select id from e3_single_coupon where fb_state<>'9' and business_date =@business_date)

group by 
      	drtd.store_code
			,drtd.store_name
			,drtd.legal_code
			,drtd.legal_name
			,drtd.city
			,drtd.business_date
			, case when   ic.firsttypeCode='10' then drtd.item_code
	                      else drtd.item_cat_mid_cod
	          end                               --13
           ,   case when   ic.firsttypeCode='10' then drtd.item_name
	              else drtd.item_cat_mid
		    	end                                --13.1
					, 'J0303'+drtd.store_code+drtd.business_date+ case when   IC.firsttypeCode='10' then drtd.item_code
	                 else drtd.item_cat_mid_cod 
	             end  
delete  from e3_single_coupon where fb_state='9' and business_date =@business_date; 

END

GO
