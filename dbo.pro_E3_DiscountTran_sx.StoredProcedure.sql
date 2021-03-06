USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[pro_E3_DiscountTran_sx]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:  根据CR405 陕西折扣数据直接传输ERP接口
--Loyalty按站、按天、按SKU所属中类、按销项税率、按促销类型（油品油非互动和油非互动外、非油品油非互动和油非互动外）生成数据直接传输至ERP
--201029   V1.0 
--exec pro_E3_DiscountTran_sx '2021-10-19'
CREATE    PROCEDURE   [dbo].[pro_E3_DiscountTran_sx]
@ProcessDate nchar(10) 
AS
BEGIN

  declare    @MatrixMemberId  int
            ,@RetailerId   varchar(2)='2';

			  select @MatrixMemberId=MatrixMemberId from  RetailCode_MP rcmp  where rcmp.RetailerId=@RetailerId   ;   ----sx RetailerId   is 2
   
   ---壳牌陕西JV希望Loyalty控制跨月促销折扣数据不传输到HOS。
      if substring(@ProcessDate,9,2)>'02' 
   delete ds_E3_Discount  where substring(business_date,1,7)<SUBSTRING(@ProcessDate,1,7)
   
 --删除dou站数据
delete    dhpd   from ds_E3_Discount  dhpd , report_data..store_gs gs 
 where dhpd.store_code=gs.storeid and dhpd.RetailerId=@RetailerId and gs.StoreType= 'DO' 


   --hos促销折扣

     
  	update      E3_Discount  set fb_state='9'
	   where    create_date=@ProcessDate
	       and  fb_state in ('0','E') and RetailerId=@RetailerId  ;

---update id
  update  dhpd  set id= dhpd.RetailerId+dhpd.store_code+convert(varchar(8),convert(date,dhpd.business_date,120),112)+convert(varchar(8),dhpd.create_date,112)
  + case when   dhpd.item_name='10' then dhpd.itemCode
	                      else dhpd.item_cat_mid_cod END
  		 +taxCode+case       when isnull(dhpd.RequiredCoupon,0)=0 or (isnull(dhpd.RequiredCoupon,0)=1 and StationCoupon=1)  then 
			                  case when  PromtionType=1  then 'Z20'  --Loyalty促销设置“是否油非互动”为“是”
							        when  PromtionType=0  then  'Z10'  END  -- 油品和非油品， Loyalty促销设置“是否油非互动”为“否”
                          ELSE   CASE WHEN PromtionType=1 AND StationCoupon=0 THEN 'Z40' --公司端发行的优惠券 包含油品和非油品促销使用了优惠券
						          WHEN PromtionType=0 AND StationCoupon=0 THEN  'Z50' end --包含油品和非油品促销使用了优惠券
								end  
		 from ds_E3_Discount dhpd
		   where 
	  PromotionId is not null 

 
INSERT INTO [dbo].[E3_Discount]
           ([RetailerId]  --1
           ,[id]                 --2
           ,[store_code]        --3
           ,[store_name]            --4
           ,[ProfitCenter]         --5
           ,[business_date]         --6
           ,[PromotionType]         --7
           ,[PromotionTypeName]      --8
           ,[itemCode]        --9
           ,[quanlity]      --10
           ,[unit]         --11
           ,[DiscountAmount] --12
           ,[DiscountTax]   --13
           ,[etl_date]   --14
           ,[etl_time]   --15
           ,[fb_state]   --16
           ,[create_date]  --17
           ,BusinessType   --18
           ,[OperationMode]  --19
          
           ,[Currency]   --20
		   ,legal_code
		   ,legal_name
		   ,TaxCode
		   )

	  select dhpd.RetailerId       --1 
	        ,dhpd.id             --2
			,dhpd.store_code		--		--3
			,dhpd.store_name				--4
			,'P'+  dhpd.LegalCode+'1'+dhpd.store_code  ProfitCenter           --5
			,dhpd.business_date				--6
			 
		 ,case       when isnull(dhpd.RequiredCoupon,0)=0 or (isnull(dhpd.RequiredCoupon,0)=1 and StationCoupon=1)  then 
			                  case when  PromtionType=1  then 'Z20'  --Loyalty促销设置“是否油非互动”为“是”
							        when  PromtionType=0  then  'Z10'  END  -- 油品和非油品， Loyalty促销设置“是否油非互动”为“否”
                          ELSE   CASE WHEN PromtionType=1 AND StationCoupon=0 THEN 'Z40' --公司端发行的优惠券 包含油品和非油品促销使用了优惠券
						          WHEN PromtionType=0 AND StationCoupon=0 THEN  'Z50' end --包含油品和非油品促销使用了优惠券
								end    PromotionType  --7

			,case       when  dhpd.RequiredCoupon=0 or (isnull(dhpd.RequiredCoupon,0)=1 and StationCoupon=1)  then 
			                  case when  PromtionType=1 then N'油非互动'  --Loyalty促销设置“是否油非互动”为“是”
							        when  PromtionType=0  then  N'油非互动外'  END  -- 油品和非油品， Loyalty促销设置“是否油非互动”为“否”
                          ELSE   CASE WHEN PromtionType=1 AND StationCoupon=0 THEN N'非积分商城优惠券油非互动' --公司端发行的优惠券 包含油品和非油品促销使用了优惠券
						          WHEN PromtionType=0 AND StationCoupon=0 THEN  N'非积分商城优惠券油非互动外' end --包含油品和非油品促销使用了优惠券
								end   --8

			,	 case when   dhpd.item_name='10' then dhpd.itemCode
	                      else dhpd.item_cat_mid_cod
	          end     --9
			,sum(dhpd.quanlity)   --10
			,''
					,round(SUM((dhpd.SaleAmount-dhpd.ReceiveAmount)/(1+isnull(taxcode.taxrate,1))),2) AS DiscountAmount   --12
			,sum(dhpd.SaleAmount-dhpd.ReceiveAmount)- round(SUM((dhpd.SaleAmount-dhpd.ReceiveAmount)/(1+isnull(taxcode.taxrate,1))),2) as [DiscountTax]   --13
			   ,convert(varchar(10),getdate(),120)  --14
          ,convert(varchar(12),getdate(),114)   --15
	                     
		   ,'0'   fb_state	   --16					 
		   ,convert(varchar(10),create_date,120)	--17 
		   ,'C02'  BusinessType    --18
           ,'Z01' [OperationMode]  --19
		   ,'CNY'  Currency         --20  
		   , dhpd.LegalCode LegalCode
		   ,dhpd.LegalName
		   ,dhpd.taxCode
	     from ds_E3_Discount dhpd
		left join TaxCode on taxCode.TaxCode=dhpd.taxCode
		   where 
	 	  		 
	 not exists	  (select 1 from E3_Discount where fb_state<>'9'   
	 and id=dhpd.id
					   )

group by 
      	  dhpd.RetailerId       --1 
	        ,dhpd.id             --2
			,dhpd.store_code		--		--3
			,dhpd.store_name				--4
			,'P'+  dhpd.LegalCode+dhpd.store_code           --5
			,dhpd.business_date				--6
			 
		 ,case       when isnull(dhpd.RequiredCoupon,0)=0 or (isnull(dhpd.RequiredCoupon,0)=1 and StationCoupon=1)  then 
			                  case when  PromtionType=1  then 'Z20'  --Loyalty促销设置“是否油非互动”为“是”
							        when  PromtionType=0  then  'Z10'  END  -- 油品和非油品， Loyalty促销设置“是否油非互动”为“否”
                          ELSE   CASE WHEN PromtionType=1 AND StationCoupon=0 THEN 'Z40' --公司端发行的优惠券 包含油品和非油品促销使用了优惠券
						          WHEN PromtionType=0 AND StationCoupon=0 THEN  'Z50' end --包含油品和非油品促销使用了优惠券
								end     --7

			,case       when  dhpd.RequiredCoupon=0 or (isnull(dhpd.RequiredCoupon,0)=1 and StationCoupon=1)  then 
			                  case when  PromtionType=1 then N'油非互动'  --Loyalty促销设置“是否油非互动”为“是”
							        when  PromtionType=0  then  N'油非互动外'  END  -- 油品和非油品， Loyalty促销设置“是否油非互动”为“否”
                          ELSE   CASE WHEN PromtionType=1 AND StationCoupon=0 THEN N'非积分商城优惠券油非互动' --公司端发行的优惠券 包含油品和非油品促销使用了优惠券
						          WHEN PromtionType=0 AND StationCoupon=0 THEN  N'非积分商城优惠券油非互动外' end --包含油品和非油品促销使用了优惠券
								end   --8

			,case when   dhpd.item_name='10' then dhpd.itemCode
	                      else dhpd.item_cat_mid_cod
	          end    --9
			, id,create_date
			, dhpd.LegalCode 
		   ,dhpd.LegalName
		   ,dhpd.TaxCode
delete  from [E3_Discount] where fb_state='9'
 and create_date =@ProcessDate  and RetailerId=@RetailerId  ; 


 	
END



GO
