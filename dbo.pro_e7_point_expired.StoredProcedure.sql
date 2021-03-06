USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[pro_e7_point_expired]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description: 提取到期的积分信息,包括注册油站,交易油站等信息,条件是postraninternalkey等于-999
-- =============================================
CREATE PROCEDURE [dbo].[pro_e7_point_expired]
	@business_date varchar(10) 
	 
AS
BEGIN

 declare @bal int =50 --per 6  point  for 1 rmb
 --@business_date varchar(10)='2017-06-06' 
update      [e7_point_expired]  set fb_state='9'
	   where    period=substring(@business_date,1,4)+substring(@business_date,6,2) 
	       and  fb_state in ('0','E');
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
	      ,case when store.comp is null then gs.sku  else store.sku end   commodity_type                               --默认油料号                --13
          ,case when store.comp is null then gs.itemname  else store.itemname end item_name    
		  ,sum(cpard.RedeemValue) point_number
		  ,sum(cpard.RedeemValue/@bal)  as point_amount
		  ,'' -- case when cpt.posid>0 then 'J0101' else 'J0102' end  jfywlx --J0101	交易积分发行  J0102	注册奖励积分
		  ,case when cpt.posid>0 then 'J11' else 'J10' end   +gs.storeid
		     +case when  store.storeid is null then gs.storeid else store.storeid end+substring(@business_date,1,7)  id
	      ,	'0'   fb_state             
		
	  from  Loyalty_Shell_prod.dbo.CRM_PosAccountsActivity_RewardLog  cpard
	  left join Loyalty_Shell_prod.dbo.CRM_POSTran cpt  on cpard.Earn_PosTranInternalKey=cpt.POSTranInternalKey 
	  left join store_gs store on store.StoreInternalKey=cpt.StoreInternalKey and cpt.MatrixMemberId=store.MatrixMemberId
	  left join   Loyalty_Shell_prod.dbo.CRM_PosAccountsActivity cpaa on cpaa.PosTranInternalKey=cpard.Earn_PosTranInternalKey
	            
	  left join  report_data.dbo.v_get_reg_compAndStore  gs on cpt.BuyingUnitInternalKey=gs.BuyingUnitInternalKey and cpt.MatrixMemberId=1
	   and gs.MatrixMemberId=cpt.MatrixMemberId
	    where  cpard.RewardStatusId=2 and convert(varchar(7),cpard.ProcessDate,120)=substring(@business_date,1,7)  
		and case when cpt.posid>0 then 'J11' else 'J10' end +gs.storeid
		  +case when  store.storeid is null then gs.storeid else store.storeid end     is not null 
		  and gs.MatrixMemberId=1 and cpaa.MatrixMemberId=1 and cpt.MatrixMemberId=1
      group by  
	    gs.compID 
	   ,gs.storeid  
	   ,gs.storename  
	   , case when  store.storeid is null then gs.storeid else store.storeid end  
		 ,case when store.storename is null then gs.storeName else store.storename end  

	      ,case when  store.compID is null then gs.compid else store.compID end 
		  ,case when store.comp is null then gs.comp  else store.comp end  
		  ,gs.city
		  ,case when store.comp is null then gs.sku  else store.sku end                                 --默认油料号                --13
          ,case when store.comp is null then gs.itemname  else store.itemname end    

		  ,case when cpt.posid>0 then 'J11' else 'J10' end   
	      ,case when cpt.posid>0 then 'J11' else 'J10' end  +gs.storeid
		  +case when  store.storeid is null then gs.storeid else store.storeid end+substring(@business_date,1,7)   
  
   
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
	      ,'1000' commodity_type                               --默认油料号                --13
          ,N'油品92号' item_name    
		  ,sum(r52.expire_je*@bal) point_number
		  ,sum(r52.expire_je)  as point_amount
		  ,'' -- case when cpt.posid>0 then 'J0101' else 'J0102' end  jfywlx --J0101	交易积分发行  J0102	注册奖励积分
		  , 'J12'  +r52.reg_storeid  +reg_compid+substring(@business_date,1,7)  id
	      ,	'0'   fb_state             
		
	   from  report_data.[dbo].[R52_coupon_expire] R52
	  
      group by  
	 R52.reg_compid
	       ,  R52.reg_storeid 
	,     R52.reg_storename
	   ,reg_storeid
		 ,reg_storename

	      ,reg_compid
		  ,reg_comp 
		 ,'J12'  +r52.reg_storeid  +reg_compid+substring(@business_date,1,7)  


delete  from e7_point_expired  where fb_state='9' and period=substring(@business_date,1,4)+substring(@business_date,6,2); 

END


GO
