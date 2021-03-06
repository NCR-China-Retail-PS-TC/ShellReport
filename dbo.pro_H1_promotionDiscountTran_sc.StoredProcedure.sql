USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[pro_H1_promotionDiscountTran_sc]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE   [dbo].[pro_H1_promotionDiscountTran_sc]
@ProcessDate nchar(10) 
AS
BEGIN

  declare    @MatrixMemberId  int=5
            ,@RetailerId   varchar(2);

			select @RetailerId=r.RetailerId   from  RetailCode_MP r where r.MatrixMemberId=@MatrixMemberId
   --hos促销折扣
     
  	update      [h1_PromotionDiscountTran]  set fb_state='9'
	   where    create_date=@ProcessDate
	       and  fb_state in ('0','E') and RetailerId=@RetailerId  ;
---update id
  update  dhpd  set id= dhpd.RetailerId+dhpd.store_code+convert(varchar(8),convert(date,dhpd.business_date,120),112)+convert(varchar(8),dhpd.create_date,112)+PromotionId+itemCode
		 +convert(varchar(1),isnull(RequiredCoupon,0))+isnull(PromtionType,'')+convert(varchar(1),isnull(StationCoupon,0))+threshold    from ds_h1_PromotionDiscount dhpd
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
		 ,    case       when dhpd.RequiredCoupon=0 or (dhpd.RequiredCoupon=1 and  StationCoupon=1)  then    --1
		             case when  PromtionType=0 then                                                          --1.1
					     
					   case   when SUM(dhpd.SaleAmount)<>0 and threshold='0'  then  'S20'       --S20 油非互动外促销-折扣-无门槛 
						  else   'S10'   --NOthreshold S10 油非互动外促销-折扣-有门槛  1.1.1                                                   --              1.1.1
						 end		                                                                           --1.1.1
                      else                                                                       --1.1 
					       case  when SUM(dhpd.SaleAmount)<>0 and  threshold='0'   then 'S40'  --S40 油非互动促销-无门槛
						  
					     else   'S30'   -- S30 油非互动促销-有门槛 NOthreshold
						 end		    
                      end  
			  else
			    case when  PromtionType=0 then                                                          --1.1
					     case when SUM(dhpd.SaleAmount)<>0 and threshold='0'  then  'S60'  --S60 油站端发行的优惠券（促销方式）-油非互动外- 无门槛  
					     else   'S50'   --  S50 油站端发行的优惠券（促销方式）-油非互动外-有门槛NOthreshold  1.1.1
						                                                         --              1.1.1
						 end		                                                                           --1.1.1
                      else                                                                       --1.1 
					       case   when SUM(dhpd.SaleAmount)<>0 and threshold='0'  then 'S80'   --S80 油站端发行的优惠券（促销方式）-油非互动-无门槛
			  
					     else   'S70'   -- S70 油站端发行的优惠券（促销方式）-油非互动-有门槛NOthreshold 			 end		    
                      end
					  end  
			  end                                                                                       



	           
				 	
				
			,  case       when dhpd.RequiredCoupon=0 or (dhpd.RequiredCoupon=1 and  StationCoupon=1)  then    --1
		                  case when  PromtionType=0 then 
					 
					    case   when SUM(dhpd.SaleAmount)<>0 and threshold='0'  then  N'S20 油非互动外促销-折扣-无门槛'      --S20 油非互动外促销-折扣-无门槛 
						  else   N'S10 油非互动外促销-折扣-有门槛'  --NOthreshold S10 油非互动外促销-折扣-有门槛  1.1.1                                                   --              1.1.1
						 end		                                                                           --1.1.1
                      else                                                                       --1.1 
					       case  when SUM(dhpd.SaleAmount)<>0 and threshold='0'   then  N'S40 油非互动促销-无门槛' --S40 油非互动促销-无门槛
						  
					     else    N'S30 油非互动促销-有门槛'   -- S30 油非互动促销-有门槛 NOthreshold
						 end		    
                      end  
					 
					 
			 
					 
					                                                          --1.1
				
			  else


			     case when  PromtionType=0 then                                                          --1.1
					     case when SUM(dhpd.SaleAmount)<>0 and threshold='0'  then   N'S60 油站端发行的优惠券（促销方式）-油非互动外- 无门槛'  --S60 油站端发行的优惠券（促销方式）-油非互动外- 无门槛  
					     else    N'S50 油站端发行的优惠券（促销方式）-油非互动外-有门槛'   --  S50 油站端发行的优惠券（促销方式）-油非互动外-有门槛NOthreshold  1.1.1
						                                                         --              1.1.1
						 end		                                                                           --1.1.1
                      else                                                                       --1.1 
					       case   when SUM(dhpd.SaleAmount)<>0 and threshold='0'  then N'S80 油站端发行的优惠券（促销方式）-油非互动-无门槛'   --S80 油站端发行的优惠券（促销方式）-油非互动-无门槛
			  
					     else   N'S70 油站端发行的优惠券（促销方式）-油非互动-有门槛'   -- S70 油站端发行的优惠券（促销方式）-油非互动-有门槛NOthreshold 			 end		    
                      end
					  end  
			    
			  end                                                                                       

			,dhpd.itemCode
			,sum(dhpd.quanlity)
			,''
			,SUM(dhpd.SaleAmount) AS saleAmount
			,sum(dhpd.ReceiveAmount) as ReceiveAmount
		   ,convert(varchar(10),getdate(),120)  --10
          ,convert(varchar(12),getdate(),114)   --11
	     , /* dhpd.RetailerId+dhpd.store_code+convert(varchar(8),convert(date,dhpd.business_date,120),112)+convert(varchar(8),dhpd.create_date,112)+PromotionId+itemCode
		 +convert(varchar(1),isnull(RequiredCoupon,0))+isnull(PromtionType,'')+convert(varchar(1),isnull(StationCoupon,0))+threshold as */          id                       --18
		   ,'0'   fb_state						--19
		   ,convert(varchar(10),create_date,120)	 
		                    
	    from ds_h1_PromotionDiscount dhpd
		   where  StoreType<>'DO' AND 
	/*  dhpd.RetailerId+dhpd.store_code+convert(varchar(8),convert(date,dhpd.business_date,120),112)+convert(varchar(8),dhpd.create_date,112)+PromotionId+itemCode
		 +convert(varchar(1),isnull(RequiredCoupon,0))+isnull(PromtionType,'')+convert(varchar(1),isnull(StationCoupon,0))+threshold  not in (select id from h1_PromotionDiscountTran where fb_state<>'9' and create_date =@ProcessDate)
		 */
		 not exists (select id from h1_PromotionDiscountTran h where fb_state<>'9' and create_date =@ProcessDate and h.id=dhpd.id )
					   and PromotionId is not null 

group by 
      	   dhpd.RetailerId
			,dhpd.store_code				--4
			,dhpd.store_name				--5
			,dhpd.business_date				--9
			,dhpd.PromotionId
			,dhpd.PromotionDesc
			,dhpd.RequiredCoupon
			,StationCoupon
			,PromtionType
			,dhpd.itemCode
			,threshold
			,id /* dhpd.RetailerId+dhpd.store_code+convert(varchar(8),convert(date,dhpd.business_date,120),112)+convert(varchar(8),dhpd.create_date,112)+PromotionId+itemCode
		 +convert(varchar(1),isnull(RequiredCoupon,0))+isnull(PromtionType,'')+convert(varchar(1),isnull(StationCoupon,0))
		 */
				,create_date

-----------


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
