USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[pro_H1_promotionDiscountTran]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	hos促销折扣
-- =============================================
CREATE  PROCEDURE   [dbo].[pro_H1_promotionDiscountTran]
@ProcessDate nchar(10) 
AS
BEGIN

  declare    @MatrixMemberId  varchar(1)='2'
            ,@RetailerId   varchar(2);

			select @RetailerId=r.RetailerId   from  RetailCode_MP r where r.MatrixMemberId=@MatrixMemberId
   --hos促销折扣
     
  	update      [h1_PromotionDiscountTran]  set fb_state='9'
	   where    create_date=@ProcessDate
	       and  fb_state in ('0','E') and RetailerId=@RetailerId  ;


		   	  select dhpd.RetailerId
			,dhpd.store_code				--4
			,dhpd.store_name				--5
			,dhpd.business_date				--9
			,dhpd.PromotionId
			,dhpd.PromotionDesc
		 ,case       when isnull(dhpd.RequiredCoupon,0)=0 or (isnull(dhpd.RequiredCoupon,0)=1 and ShopCoupon=1)  then 
			                  case when  PromtionType=1  then 'Z20'  --Loyalty促销设置“是否油非互动”为“是”
							        when  PromtionType=0  then  'Z10'  END  -- 油品和非油品， Loyalty促销设置“是否油非互动”为“否”
                          ELSE   CASE WHEN PromtionType=1 AND ShopCoupon=0 THEN 'Z40' --公司端发行的优惠券 包含油品和非油品促销使用了优惠券
						          WHEN PromtionType=0 AND ShopCoupon=0 THEN  'Z50' end --包含油品和非油品促销使用了优惠券
								end 

			,case       when  dhpd.RequiredCoupon=0 or (isnull(dhpd.RequiredCoupon,0)=1 and ShopCoupon=1)  then 
			                  case when  PromtionType=1 then N'油非互动'  --Loyalty促销设置“是否油非互动”为“是”
							        when  PromtionType=0  then  N'油非互动外'  END  -- 油品和非油品， Loyalty促销设置“是否油非互动”为“否”
                          ELSE   CASE WHEN PromtionType=1 AND ShopCoupon=0 THEN N'非积分商城优惠券油非互动' --公司端发行的优惠券 包含油品和非油品促销使用了优惠券
						          WHEN PromtionType=0 AND ShopCoupon=0 THEN  N'非积分商城优惠券油非互动外' end --包含油品和非油品促销使用了优惠券
								end 

			,dhpd.itemCode
			,sum(dhpd.quanlity)
			,''
			,SUM(dhpd.SaleAmount) AS saleAmount
			,sum(dhpd.ReceiveAmount) as ReceiveAmount
		   ,convert(varchar(10),getdate(),120)  --10
          ,convert(varchar(12),getdate(),114)   --11
	     ,  dhpd.RetailerId+dhpd.store_code+convert(varchar(8),dhpd.business_date,112)+convert(varchar(8),dhpd.create_date,112)+PromotionId+itemCode
		 +convert(varchar(1),isnull(RequiredCoupon,0))+isnull(PromtionType,'')+convert(varchar(1),isnull(ShopCoupon,0)) as          id                       --18
		   ,'0'   fb_state						--19
		   ,convert(varchar(10),create_date,120)	 
		                    
	    from ds_h1_PromotionDiscount dhpd
		   where 
	  dhpd.RetailerId+dhpd.store_code+convert(varchar(8),dhpd.business_date,112)+convert(varchar(8),dhpd.create_date,112)+PromotionId+itemCode
		 +convert(varchar(1),isnull(RequiredCoupon,0))+isnull(PromtionType,'')+convert(varchar(1),isnull(ShopCoupon,0))  not in (select id from h1_PromotionDiscountTran where fb_state<>'9' and create_date =@ProcessDate)
					   and PromotionId is not null 

group by 
      	   dhpd.RetailerId
			,dhpd.store_code				--4
			,dhpd.store_name				--5
			,dhpd.business_date				--9
			,dhpd.PromotionId
			,dhpd.PromotionDesc
			 ,case       when isnull(dhpd.RequiredCoupon,0)=0 or (isnull(dhpd.RequiredCoupon,0)=1 and ShopCoupon=1)  then 
			                  case when  PromtionType=1  then 'Z20'  --Loyalty促销设置“是否油非互动”为“是”
							        when  PromtionType=0  then  'Z10'  END  -- 油品和非油品， Loyalty促销设置“是否油非互动”为“否”
                          ELSE   CASE WHEN PromtionType=1 AND ShopCoupon=0 THEN 'Z40' --公司端发行的优惠券 包含油品和非油品促销使用了优惠券
						          WHEN PromtionType=0 AND ShopCoupon=0 THEN  'Z50' end --包含油品和非油品促销使用了优惠券
								end 

			,case       when  dhpd.RequiredCoupon=0 or (isnull(dhpd.RequiredCoupon,0)=1 and ShopCoupon=1)  then 
			                  case when  PromtionType=1 then N'油非互动'  --Loyalty促销设置“是否油非互动”为“是”
							        when  PromtionType=0  then  N'油非互动外'  END  -- 油品和非油品， Loyalty促销设置“是否油非互动”为“否”
                          ELSE   CASE WHEN PromtionType=1 AND ShopCoupon=0 THEN N'非积分商城优惠券油非互动' --公司端发行的优惠券 包含油品和非油品促销使用了优惠券
						          WHEN PromtionType=0 AND ShopCoupon=0 THEN  N'非积分商城优惠券油非互动外' end --包含油品和非油品促销使用了优惠券
								end 


			,dhpd.itemCode
			, dhpd.RetailerId+dhpd.store_code+convert(varchar(8),dhpd.business_date,112)+convert(varchar(8),dhpd.create_date,112)+PromotionId+itemCode
		 +convert(varchar(1),isnull(RequiredCoupon,0))+isnull(PromtionType,'')+convert(varchar(1),isnull(ShopCoupon,0))
				,create_date
		  
  insert  into   [report_data].[dbo].[h1_PromotionDiscountTran]
      (  [RetailerId]
     
      ,[store_code]
      ,[store_name]
      ,[business_date]
      ,[PromotionId]
      ,[PromotionDesc]
      ,[PromtionType]
      ,[PromtionTypeName]
      ,[itemCode]
      ,[quanlity]
      ,[unit]
     ,[SaleAmount]
     ,[ReceiveAmount]
      ,[etl_date]
      ,[etl_time]
	   ,[id]
      ,[fb_state]
     
	   ,create_date     )


	  select dhpd.RetailerId
			,dhpd.store_code				--4
			,dhpd.store_name				--5
			,dhpd.business_date				--9
			,dhpd.PromotionId
			,dhpd.PromotionDesc
		 ,case       when isnull(dhpd.RequiredCoupon,0)=0 or (isnull(dhpd.RequiredCoupon,0)=1 and ShopCoupon=1)  then 
			                  case when  PromtionType=1  then 'Z20'  --Loyalty促销设置“是否油非互动”为“是”
							        when  PromtionType=0  then  'Z10'  END  -- 油品和非油品， Loyalty促销设置“是否油非互动”为“否”
                          ELSE   CASE WHEN PromtionType=1 AND ShopCoupon=0 THEN 'Z40' --公司端发行的优惠券 包含油品和非油品促销使用了优惠券
						          WHEN PromtionType=0 AND ShopCoupon=0 THEN  'Z50' end --包含油品和非油品促销使用了优惠券
								end 

			,case       when  dhpd.RequiredCoupon=0 or (isnull(dhpd.RequiredCoupon,0)=1 and ShopCoupon=1)  then 
			                  case when  PromtionType=1 then N'油非互动'  --Loyalty促销设置“是否油非互动”为“是”
							        when  PromtionType=0  then  N'油非互动外'  END  -- 油品和非油品， Loyalty促销设置“是否油非互动”为“否”
                          ELSE   CASE WHEN PromtionType=1 AND ShopCoupon=0 THEN N'非积分商城优惠券油非互动' --公司端发行的优惠券 包含油品和非油品促销使用了优惠券
						          WHEN PromtionType=0 AND ShopCoupon=0 THEN  N'非积分商城优惠券油非互动外' end --包含油品和非油品促销使用了优惠券
								end 

			,dhpd.itemCode
			,sum(dhpd.quanlity)
			,''
			,SUM(dhpd.SaleAmount) AS saleAmount
			,sum(dhpd.ReceiveAmount) as ReceiveAmount
		   ,convert(varchar(10),getdate(),120)  --10
          ,convert(varchar(12),getdate(),114)   --11
	     ,  dhpd.RetailerId+dhpd.store_code+convert(varchar(8),dhpd.business_date,112)+convert(varchar(8),dhpd.create_date,112)+PromotionId+itemCode
		 +convert(varchar(1),isnull(RequiredCoupon,0))+isnull(PromtionType,'')+convert(varchar(1),isnull(ShopCoupon,0)) as          id                       --18
		   ,'0'   fb_state						--19
		   ,convert(varchar(10),create_date,120)	 
		                    
	    from ds_h1_PromotionDiscount dhpd
		   where 
	  dhpd.RetailerId+dhpd.store_code+convert(varchar(8),dhpd.business_date,112)+convert(varchar(8),dhpd.create_date,112)+PromotionId+itemCode
		 +convert(varchar(1),isnull(RequiredCoupon,0))+isnull(PromtionType,'')+convert(varchar(1),isnull(ShopCoupon,0))  not in (select id from h1_PromotionDiscountTran where fb_state<>'9' and create_date =@ProcessDate)
					   and PromotionId is not null 

group by 
      	   dhpd.RetailerId
			,dhpd.store_code				--4
			,dhpd.store_name				--5
			,dhpd.business_date				--9
			,dhpd.PromotionId
			,dhpd.PromotionDesc
			 ,case       when isnull(dhpd.RequiredCoupon,0)=0 or (isnull(dhpd.RequiredCoupon,0)=1 and ShopCoupon=1)  then 
			                  case when  PromtionType=1  then 'Z20'  --Loyalty促销设置“是否油非互动”为“是”
							        when  PromtionType=0  then  'Z10'  END  -- 油品和非油品， Loyalty促销设置“是否油非互动”为“否”
                          ELSE   CASE WHEN PromtionType=1 AND ShopCoupon=0 THEN 'Z40' --公司端发行的优惠券 包含油品和非油品促销使用了优惠券
						          WHEN PromtionType=0 AND ShopCoupon=0 THEN  'Z50' end --包含油品和非油品促销使用了优惠券
								end 

			,case       when  dhpd.RequiredCoupon=0 or (isnull(dhpd.RequiredCoupon,0)=1 and ShopCoupon=1)  then 
			                  case when  PromtionType=1 then N'油非互动'  --Loyalty促销设置“是否油非互动”为“是”
							        when  PromtionType=0  then  N'油非互动外'  END  -- 油品和非油品， Loyalty促销设置“是否油非互动”为“否”
                          ELSE   CASE WHEN PromtionType=1 AND ShopCoupon=0 THEN N'非积分商城优惠券油非互动' --公司端发行的优惠券 包含油品和非油品促销使用了优惠券
						          WHEN PromtionType=0 AND ShopCoupon=0 THEN  N'非积分商城优惠券油非互动外' end --包含油品和非油品促销使用了优惠券
								end 


			,dhpd.itemCode
			, dhpd.RetailerId+dhpd.store_code+convert(varchar(8),dhpd.business_date,112)+convert(varchar(8),dhpd.create_date,112)+PromotionId+itemCode
		 +convert(varchar(1),isnull(RequiredCoupon,0))+isnull(PromtionType,'')+convert(varchar(1),isnull(ShopCoupon,0))
				,create_date
delete  from h1_PromotionDiscountTran where fb_state='9'
 and create_date =@ProcessDate  and RetailerId=@RetailerId  ; 


END
GO
