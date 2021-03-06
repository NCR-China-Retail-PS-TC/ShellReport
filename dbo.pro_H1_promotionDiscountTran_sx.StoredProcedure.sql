USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[pro_H1_promotionDiscountTran_sx]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	hos促销折扣
--CR219陕西 Loyalty & HOS 接口数据传输跨月控制 20191105
--删除dou站数据 2019-11-15
CREATE  PROCEDURE   [dbo].[pro_H1_promotionDiscountTran_sx]
@ProcessDate nchar(10) 
AS
BEGIN

  declare    @MatrixMemberId  int
            ,@RetailerId   varchar(2)='2';

			  select @MatrixMemberId=MatrixMemberId from  RetailCode_MP rcmp  where rcmp.RetailerId=@RetailerId   ;   ----sx RetailerId   is 2
   
   ---壳牌陕西JV希望Loyalty控制跨月促销折扣数据不传输到HOS。
      if substring(@ProcessDate,9,2)>'02' 
   delete ds_h1_PromotionDiscount  where substring(business_date,1,7)<SUBSTRING(@ProcessDate,1,7)
   
 --删除dou站数据
delete    dhpd   from ds_h1_PromotionDiscount  dhpd , report_data..store_gs gs 
 where dhpd.store_code=gs.storeid and dhpd.RetailerId=@RetailerId and gs.StoreType= 'DO' 


   --hos促销折扣

     
  	update      [h1_PromotionDiscountTran]  set fb_state='9'
	   where    create_date=@ProcessDate
	       and  fb_state in ('0','E') and RetailerId=@RetailerId  ;

---update id
  update  dhpd  set id= dhpd.RetailerId+dhpd.store_code+convert(varchar(8),convert(date,dhpd.business_date,120),112)+convert(varchar(8),dhpd.create_date,112)+PromotionId+itemCode
		 +convert(varchar(1),isnull(RequiredCoupon,0))+isnull(PromtionType,'')+convert(varchar(1),isnull(StationCoupon,0))    from ds_h1_PromotionDiscount dhpd
		   where 
	  PromotionId is not null 

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
		 ,case       when isnull(dhpd.RequiredCoupon,0)=0 or (isnull(dhpd.RequiredCoupon,0)=1 and StationCoupon=1)  then 
			                  case when  PromtionType=1  then 'Z20'  --Loyalty促销设置“是否油非互动”为“是”
							        when  PromtionType=0  then  'Z10'  END  -- 油品和非油品， Loyalty促销设置“是否油非互动”为“否”
                          ELSE   CASE WHEN PromtionType=1 AND StationCoupon=0 THEN 'Z40' --公司端发行的优惠券 包含油品和非油品促销使用了优惠券
						          WHEN PromtionType=0 AND StationCoupon=0 THEN  'Z50' end --包含油品和非油品促销使用了优惠券
								end 

			,case       when  dhpd.RequiredCoupon=0 or (isnull(dhpd.RequiredCoupon,0)=1 and StationCoupon=1)  then 
			                  case when  PromtionType=1 then N'油非互动'  --Loyalty促销设置“是否油非互动”为“是”
							        when  PromtionType=0  then  N'油非互动外'  END  -- 油品和非油品， Loyalty促销设置“是否油非互动”为“否”
                          ELSE   CASE WHEN PromtionType=1 AND StationCoupon=0 THEN N'非积分商城优惠券油非互动' --公司端发行的优惠券 包含油品和非油品促销使用了优惠券
						          WHEN PromtionType=0 AND StationCoupon=0 THEN  N'非积分商城优惠券油非互动外' end --包含油品和非油品促销使用了优惠券
								end 

			,dhpd.itemCode
			,sum(dhpd.quanlity)
			,''
			,SUM(dhpd.SaleAmount) AS saleAmount
			,sum(dhpd.ReceiveAmount) as ReceiveAmount
		   ,convert(varchar(10),getdate(),120)  --10
          ,convert(varchar(12),getdate(),114)   --11
	     ,          id                       --18
		   ,'0'   fb_state						--19
		   ,convert(varchar(10),create_date,120)	 
		                    
	    from ds_h1_PromotionDiscount dhpd
		   where 
	 	  		 
	 not exists	  (select 1 from h1_PromotionDiscountTran where fb_state<>'9'   
	 and id=dhpd.id
					   )

group by 
      	   dhpd.RetailerId
			,dhpd.store_code				--4
			,dhpd.store_name				--5
			,dhpd.business_date				--9
			,dhpd.PromotionId
			,dhpd.PromotionDesc
			 ,case       when isnull(dhpd.RequiredCoupon,0)=0 or (isnull(dhpd.RequiredCoupon,0)=1 and StationCoupon=1)  then 
			                  case when  PromtionType=1  then 'Z20'  --Loyalty促销设置“是否油非互动”为“是”
							        when  PromtionType=0  then  'Z10'  END  -- 油品和非油品， Loyalty促销设置“是否油非互动”为“否”
                          ELSE   CASE WHEN PromtionType=1 AND StationCoupon=0 THEN 'Z40' --公司端发行的优惠券 包含油品和非油品促销使用了优惠券
						          WHEN PromtionType=0 AND StationCoupon=0 THEN  'Z50' end --包含油品和非油品促销使用了优惠券
								end 

			,case       when  dhpd.RequiredCoupon=0 or (isnull(dhpd.RequiredCoupon,0)=1 and StationCoupon=1)  then 
			                  case when  PromtionType=1 then N'油非互动'  --Loyalty促销设置“是否油非互动”为“是”
							        when  PromtionType=0  then  N'油非互动外'  END  -- 油品和非油品， Loyalty促销设置“是否油非互动”为“否”
                          ELSE   CASE WHEN PromtionType=1 AND StationCoupon=0 THEN N'非积分商城优惠券油非互动' --公司端发行的优惠券 包含油品和非油品促销使用了优惠券
						          WHEN PromtionType=0 AND StationCoupon=0 THEN  N'非积分商城优惠券油非互动外' end --包含油品和非油品促销使用了优惠券
								end 


			,dhpd.itemCode
			, id,create_date
delete  from h1_PromotionDiscountTran where fb_state='9'
 and create_date =@ProcessDate  and RetailerId=@RetailerId  ; 


 	--Reconciliation
	delete report_data..ReconciliationR2ERP 
	where RetailerId = @RetailerId 
	and DataType in ('H1')
	and CreatedAt = @ProcessDate;


	insert into report_data..ReconciliationR2ERP
	(	
		RetailerId,
		DataType,
		CreatedAt,
		BusinessDate,
		Point,
		StoreType
	)
	select @RetailerId,'H1',e.Create_date,e.business_date,sum(e.SaleAmount - e.receiveAmount),e.StoreType
	from h1_PromotionDiscountTran e
	--left join [report_data].[dbo].store_gs store on e.store_code = store.storeid
	where e.RetailerId = @RetailerId 
	and e.Create_date = @ProcessDate
	group by e.Create_date,e.business_date,e.StoreType


END



GO
