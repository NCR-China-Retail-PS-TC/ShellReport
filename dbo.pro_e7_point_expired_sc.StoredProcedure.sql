USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[pro_e7_point_expired_sc]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description: 提取到期的积分信息,包括注册油站,交易油站等信息,条件是postraninternalkey等于-999
-- =============================================
CREATE  PROCEDURE [dbo].[pro_e7_point_expired_sc]
	@business_date varchar(10) 
	 
AS
BEGIN
    
        declare @bal int =50 --per 6  point  for 1 rmb
	            ,@MatrixMemberId int
                ,@retailerID char(10) 
					,  @first_businessDate VARCHAR(10)=Substring(@business_Date, 1, 8) + '01',
              @end_businessDate   VARCHAR(10)=  convert(varchar(10),DATEADD(DAY,0,DATEADD(MM,DATEDIFF(MM,0,@business_Date)+1,0)),120)

	        set @MatrixMemberId=5
			  select @RetailerId= r.RetailerId  from  RetailCode_MP R where r.MatrixMemberId=@MatrixMemberId;

delete     [e7_point_expired]   
	   where    period=substring(@business_date,1,4)+substring(@business_date,6,2) 
	        and RetailerId=@RetailerId;
		  ;

 	 
  INSERT INTO [dbo].[e7_point_expired]
           ([member_reg_comp_code]
           ,[member_reg_store_code]
           ,[member_reg_store]
           ,[store_code]
           ,[store_name]
           ,[legal_code]
           ,[legal_name]
           ,[city]
           ,business_date
		   ,[period]
           ,[etl_date]
           ,[etl_time]
           ,[point_type]
           ,[commodity_type]
           ,[commodity_name]
           ,[point_number]
           ,[point_amount]
           ,[point_service_type]
           ,[id]
           ,[fb_state]
             ,TaxCode   --19
			,RetailerId--20
			,StoreType --21
			,DoBusinessCode  --22
			)  


	  select    gs.compID regcom
	  ,gs.storeid regStoreid
	  ,gs.storename regStoreName
	   ,case when  store.storeid is null then gs.storeid else store.storeid end storeid
		 ,case when store.storename is null then gs.storeName else store.storename end storename

	      ,case when  store.compID is null then gs.compid else store.compID end compid
		  ,case when store.comp is null then gs.comp  else store.comp end comp 
		  ,gs.city
		   , convert(varchar(10),dateadd(m,1 ,dateadd(d, -day(convert(datetime,@business_date,120)),(convert(datetime,@business_date,120)))),120)

		  ,substring(@business_date,1,4)+substring(@business_date,6,2)  as peroid
		  ,convert(varchar(10),getdate(),120)  
          ,convert(varchar(12),getdate(),114)   	
		  ,case when cpt.posid>0 then 'J11' else 'J10' end  pointType  --j10 积分到期--公司端发行 J11积分到期--油站端发行
	      , item.MainItemId commodity_type                               --默认油料号                --13
          , item.FullName  item_name    
		  ,sum(cpard.RedeemValue) point_number
		  ,sum(cpard.RedeemValue/@bal)  as point_amount
		  ,'' -- case when cpt.posid>0 then 'J0101' else 'J0102' end  jfywlx --J0101	交易积分发行  J0102	注册奖励积分
		  ,case when cpt.posid>0 then 'J11' else 'J10' end   +gs.storeid
		     +  isnull(store.storeid, gs.storeid)+gs.compID +gs.storeid+substring(@business_date,1,7)
			 + item.taxCode  id
	      ,	'0'   fb_state             
		  ,  item.taxCode    --19
			,RetailerId--20
			,store.StoreType --21
			,''DoBusinessCode  --22
	  from  Loyalty_Shell_uat.dbo.CRM_PosAccountsActivity_RewardLog  cpard
	  left join Loyalty_Shell_uat.dbo.CRM_POSTran cpt  on cpard.Earn_PosTranInternalKey=cpt.POSTranInternalKey
	  left join store_gs store on store.StoreInternalKey=cpt.StoreInternalKey  and store.MatrixMemberId=cpt.MatrixMemberId
	--  left join item_cat it on store.sku=it.MainItemId
	  left join   Loyalty_Shell_uat.dbo.CRM_PosAccountsActivity cpaa on cpaa.PosTranInternalKey=cpard.Earn_PosTranInternalKey
	     and cpaa.AccountInternalKey=2        
	  left join  report_data.dbo.v_get_reg_compAndStore  gs on cpt.BuyingUnitInternalKey=gs.BuyingUnitInternalKey  and gs.MatrixMemberId=cpt.MatrixMemberId
	 	left join report_data..store_sku sk  on  sk.MatrixMemberId=gs.MatrixMemberId and sk.CompanyId=gs.compid
		       		left join [dbo].[item_cat] item  on SK.sku=item.MainItemId and SK.MatrixMemberId=item.MatrixMemberId
	
	  inner join RetailCode_MP  rc on rc.MatrixMemberId=cpt.MatrixMemberId
	    where  cpard.RewardStatusId=2 and   cpard.ProcessDate >= convert(date,@first_businessDate,120)
		  and cpard.ProcessDate<convert(date,@end_businessDate,120) --and convert(varchar(7),cpard.ProcessDate,120)=substring(@business_date,1,7) 

		and  rc.RetailerId=@retailerID 
		and case when cpt.posid>0 then 'J11' else 'J10' end +gs.storeid
		  +case when  store.storeid is null then gs.storeid else store.storeid end     is not null 
		--  and gs.MatrixMemberId=rc.MatrixMemberId and cpaa.MatrixMemberId=rc.MatrixMemberId and cpt.MatrixMemberId=rc.MatrixMemberId
      group by  
	    gs.compID 
	   ,gs.storeid  
	   ,gs.storename  
	   , case when  store.storeid is null then gs.storeid else store.storeid end  
		 ,case when store.storename is null then gs.storeName else store.storename end  

	      ,case when  store.compID is null then gs.compid else store.compID end 
		  ,case when store.comp is null then gs.comp  else store.comp end  
		  ,gs.city
		  , item.MainItemId                                --默认油料号                --13
          , item.FullName  
		  ,case when cpt.posid>0 then 'J11' else 'J10' end   
	       ,case when cpt.posid>0 then 'J11' else 'J10' end   +gs.storeid
		     +  isnull(store.storeid, gs.storeid)+gs.compID +gs.storeid+substring(@business_date,1,7)
			 + item.taxCode 
	       ,  item.taxCode    --19
			,RetailerId--20
          ,store.StoreType --21


 -------------------------
	  --优惠券到期
	  -------------------------
 
	

  INSERT INTO [dbo].[e7_point_expired]
           ([member_reg_comp_code]
           ,[member_reg_store_code]
           ,[member_reg_store]
           ,[store_code]
           ,[store_name]
           ,[legal_code]
           ,[legal_name]
           ,[city]
           ,business_date
		   ,[period]
           ,[etl_date]
           ,[etl_time]
           ,[point_type]
           ,[commodity_type]
           ,[commodity_name]
           ,[point_number]
           ,[point_amount]
           ,[point_service_type]
           ,[id]
           ,[fb_state]
           ,TaxCode   --19
			,RetailerId--20
			,StoreType --21
			,DoBusinessCode  --22
			)  


	  select  R52.reg_compid 
	       ,  R52.reg_storeid regStoreid
	,     R52.reg_storename regStoreName
	   ,reg_storeid
		 ,reg_storename

	      ,reg_compid
		  ,reg_comp 
		  ,''
		   , convert(varchar(10),dateadd(m,1 ,dateadd(d, -day(convert(datetime,@business_date,120)),(convert(datetime,@business_date,120)))),120)

		  ,substring(@business_date,1,4)+substring(@business_date,6,2)  as peroid
		  ,convert(varchar(10),getdate(),120)  
          ,convert(varchar(12),getdate(),114)   	
		  ,'J12'    pointType  --j10 积分到期--公司端发行 J11积分到期--油站端发行,J12优惠券到期
	      ,item.MainItemId commodity_type                               --默认油料号                --13
          ,item.FullName item_name    
		  ,sum(r52.expire_je*@bal) point_number
		  ,sum(r52.expire_je)  as point_amount
		  ,'' -- case when cpt.posid>0 then 'J0101' else 'J0102' end  jfywlx --J0101	交易积分发行  J0102	注册奖励积分
		  , 'J12'  +r52.reg_storeid  +reg_compid+@business_date+item.taxcode  id
	      ,	'0'   fb_state  
		   ,item.taxcode   --19
			,RetailerId--20           
	    	,''--,gs.StoreType --21
			,''DoBusinessCode  --22
	   from  report_data.[dbo].[R52_coupon_expire] R52
	   
		left join [dbo].[store_gs] gs on r52.reg_storeid=gs.storeid
		left join report_data..store_sku sk  on  sk.MatrixMemberId=gs.MatrixMemberId and sk.CompanyId=gs.compid
		     
		left join [dbo].[item_cat] item  on SK.sku=item.MainItemId and SK.MatrixMemberId=item.MatrixMemberId

		where  R52.RetailerId=@retailerID 
      group by  
	 R52.reg_compid
	       ,  R52.reg_storeid 
	,     R52.reg_storename
	   ,reg_storeid
		 ,reg_storename

	      ,reg_compid
		  ,reg_comp 
		 ,'J12'  +r52.reg_storeid  +reg_compid+substring(@business_date,1,7)
		 ,item.MainItemId                                --默认油料号                --13
          ,item.FullName    
		  ,item.TaxCode   --19
			,RetailerId--20
			,gs.StoreType
 
  

delete  from e7_point_expired  where fb_state='9' and
 period=substring(@business_date,1,4)+substring(@business_date,6,2)   and RetailerId=@RetailerId; 


 	--Reconciliation
	delete report_data..ReconciliationR2ERP 
	where RetailerId = @RetailerId 
	and DataType in ('E7')
	and CreatedAt = substring(@business_date,1,4)+substring(@business_date,6,2)


	insert into report_data..ReconciliationR2ERP
	(	
		RetailerId,
		DataType,
		CreatedAt,
		BusinessDate,
		Point,
		StoreType
	)
	select @RetailerId,'E7',e.period,e.period,sum(e.point_number),e.StoreType
	from e7_point_expired e
	where e.RetailerId = @RetailerId 
	and e.period = substring(@business_date,1,4)+substring(@business_date,6,2)
	group by e.period,e.StoreType

END



GO
