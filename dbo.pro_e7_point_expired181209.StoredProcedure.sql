USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[pro_e7_point_expired181209]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description: 提取到期的积分信息,包括注册油站,交易油站等信息,条件是postraninternalkey等于-999
-- =============================================
create  PROCEDURE [dbo].[pro_e7_point_expired181209]
	@business_date varchar(10) 
	 
AS
BEGIN

 declare @bal int =20 --per 6  point  for 1 rmb
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


	  select mgs.compID regcom
	  ,mgs.storeid regStoreid
	  ,mgs.storename regStoreName
	   ,case when  gs.storeid is null then mgs.storeid else gs.storeid end storeid
		 ,case when gs.storename is null then mgs.storeName else gs.storename end storename

	      ,case when  gs.compID is null then mgs.compid else gs.compID end compid
		  ,case when gs.comp is null then mgs.comp  else gs.comp end comp 
		  ,mgs.city
		   , convert(varchar(10),dateadd(m,1 ,dateadd(d, -day(convert(datetime,@business_date,120)),(convert(datetime,@business_date,120)))),120)

		  ,substring(@business_date,1,4)+substring(@business_date,6,2)  as peroid
		  ,convert(varchar(10),getdate(),120)  
          ,convert(varchar(12),getdate(),114)   	
		  ,case when cpt.posid>0 then 'J11' else 'J10' end  pointType  --j10 积分到期--公司端发行 J11积分到期--油站端发行
	      ,'1000' commodity_type                               --默认油料号                --13
          ,N'油品92号' item_name    
		  ,sum(cpard.redemBalance) point_number
		  ,sum(cpard.redemBalance/@bal)  as point_amount
		  ,'' -- case when cpt.posid>0 then 'J0101' else 'J0102' end  jfywlx --J0101	交易积分发行  J0102	注册奖励积分
		  ,case when cpt.posid>0 then 'J11' else 'J10' end +mgs.storeid
		  +case when  gs.storeid is null then mgs.storeid else gs.storeid end+substring(@business_date,1,7)  id
	      ,	'0'   fb_state             
		
	   from  report_data.[dbo].CRM_POSAccountsActivitRedemDetail cpard
	  left join Loyalty_Shell_Prod.dbo.CRM_POSTran cpt  on cpard.PosTranInternalKey=cpt.POSTranInternalKey
	  left join store_gs gs on gs.StoreInternalKey=cpt.StoreInternalKey
	  left join  report_data.dbo.member_gs  mgs on cpard.BuyingUnitInternalKey=mgs.BuyingUnitInternalKey
	    where   redemPosTranInternalKey=-999 and convert(varchar(7),ExpirationDate,120)=substring(@business_date,1,7)  
      group by  
	    mgs.compID 
	  ,mgs.storeid  
	  ,mgs.storename  
	   ,case when  gs.storeid is null then mgs.storeid else gs.storeid end  
		 ,case when gs.storename is null then mgs.storeName else gs.storename end  

	      ,case when  gs.compID is null then mgs.compid else gs.compID end 
		  ,case when gs.comp is null then mgs.comp  else gs.comp end  
		  ,mgs.city
		  ,case when cpt.posid>0 then 'J11' else 'J10' end   
	      ,case when cpt.posid>0 then 'J11' else 'J10' end 
		  +case when  gs.storeid is null then mgs.storeid else gs.storeid end+substring(@business_date,1,7)   
	  

delete  from e7_point_expired  where fb_state='9' and period=substring(@business_date,1,4)+substring(@business_date,6,2); 

END


GO
