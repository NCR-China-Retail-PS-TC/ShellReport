USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[erp_ds_sx_tmp]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/****** Object:  StoredProcedure [dbo].[est]    Script Date: 2017/3/2 18:01:20 ******/

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE  PROCEDURE [dbo].[erp_ds_sx_tmp]
	 @CreatedDate varchar(10)='2017-03-01'   --yyyy-mm-dd
	AS
BEGIN
   
		 		 
		 declare @bal int =50; --per 20  point  for 1 rmb
		 declare @createDateNextday varchar(10)= dateadd( day,1,convert(date,@createddate,120))
    declare @tableDate_cur varchar(6) ,@tableDate_pre varchar(6) 
	,@atd_Server nvarchar(max) ='ATD_Shell'		
	,@ServerHost nvarchar(max)='HOST_Shell_prod'
	,@loyalty_server varchar(max)='Loyalty_Shell_prod'
	,@sql_text  nvarchar(max)
	,@sql_text_org nvarchar(max)
	, @MatrixMemberId int
	declare @RetailerId varchar(10)='2';	
	  select @MatrixMemberId=MatrixMemberId from  RetailCode_MP rcmp  	 
	   where rcmp.RetailerId=@RetailerId   ;   ----sx RetailerId   is 2
	set @TableDate_cur=SUBSTRING(REPLACE(@CreatedDate,'-',''),1,6) --设置年月
	set @TableDate_pre=SUBSTRING(REPLACE(convert( varchar,dateadd(month,-1,@CreatedDate),120),'-',''),1,6) --设置年月 数据前一个月
	
	
		

 -- print @tran_detail_reward_point_sql;
--  insert into  report_data.[dbo].[tran_detail_reward_point]  exec @tran_detail_reward_point_sql

--  R1_1  discount table 

	 
	
------------discount------------------------
----------------reward point---------------------
truncate  table  report_data.[dbo].[DS_r1_2_tran_reward] 

set @sql_text_org=N'insert into  report_data.[dbo].[DS_r1_2_tran_reward] (
            [member_card_no]              --1
           , member_reg_comp_code          --2
           , member_reg_comp			   --3
           , member_reg_store_code         --4
           , member_reg_store              --5
           ,legal_name                      --6
           ,legal_code                   --7
           , store_code                    --8 
           , store_name                    --9
           ,[city]						--10
           ,[cashierid]					--11
           ,[transaction_no]			--12
           ,[business_date]				--13
           ,[transaction_date]			--14
           ,[transaction_time]			--15
           ,[posid]						--16
           ,[item_cat]					--17
		   ,item_cat_mid_code           --18
           ,[item_cat_mid]				--19
           ,[item_code]					--20
           ,[item_name]					--21
           
           ,[reward_point]				--22
           ,[reward_amount]				--23
           ,[promtion_id]				--24
           ,[promtion_group]			--25
		   ,promtion_ref                --26
		   ,create_date                  --27
		    ,RetailerId                  --28
		    ,Storetype                   --29
           ,TaxCode                      --30
           ,PromotionType                --31
		   )
 select cp.ClubCardId          --1会员号码

,s.compid    compid            --2 
,s.comp      regcomp           --3会员注册公司
,s.storeid   storeid           --4会员注册油站     
,s.storename  regstore         --5会员注册默认油站
,store.comp as sal_com                                  --6公司
,store.compid as sal_com_id                             --7公司代码
  ,store.storeid                 --8 油站代码
 ,store.storename as stor       -- 9油站名称
 
 , store.city    city                                          --10城市
 , ftc.CashierId                         --11Cashier ID
 ,fth.TranId                              --12交易流水号
 ,convert(varchar(10),ftc.BusinessDate ,120) BusinessDate                   --13营业日
 ,convert(varchar(10),fth.StartDateTime,120)  trandate                  --14交易日期
 ,CONVERT(varchar(100), fth.StartDateTime, 8)      trantime           --15交易时间,
 ,ftc.TillId                                                                --16POS ID
, item.firsttype                     --17商品类型
,item.midtypeCode                    --18
 , item.midtype                                     --19商品中类
 ,   ftprd1.EntityId                              --20SKU
  ,  item.FullName                        --21商品
	 ,ftprd1.RewardValue as RewardvaluePoint        --22获得积分
	, round(ftprd1.RewardValue/@bal,2)   as reward_amount                            --23积分发放金额
	 ,ftprd1.PromotionId                                            --24促销id
	 ,phpr.PromotionGroupId                                 --25促销组
	 
	 ,substring(phpr.ExternalReferenceID,1,8)                             --26 外部促销id
	 ,convert(varchar(10),fth.CreatedDate,120)                  --27 上传日期
     --,rc.RetailerId                                             --28
	 ,ftc.RetailerId                                             --28
		    ,store.Storetype                                        --29
          ,item.TaxCode                                         --30
          ,PromotionType  '                                     --31
 set @sql_text_org=@sql_text_org+ N'  from   
		 [ATD_Shell].[dbo].[FO_TranCollection] ftc 
			  inner  join  [ATD_Shell].dbo.FO_TranHeader201704 fth
		 
on ftc.CollectionInternalKey=fth.CollectionInternalKey
 inner  join  [report_data].[dbo].store_gs store on store.storeid=ftc.storeid and store.MatrixMemberId=@MatrixMemberId
   left join  Loyalty_Shell_1. [dbo].[CRM_POSTran] cp 
    on cp.TranId=fth.TranId and cp.PosDateTime=ftc.BusinessDate and cp.StoreInternalKey=store.StoreInternalKey
	  and  cp.MatrixMemberId=@MatrixMemberId and cp.PosId=ftc.TillId
	--inner join [ATD_Shell].dbo.FO_TranSale201704 fts
---	on fts.TicketInternalKey=fth.TicketInternalKey
   left join (select  distinct  TicketInternalKey, ftprd1.PromotionId ,ftprd1.RewardValue , entityid 
  from  report_data..FO_TranPromotionRewardApportionment2020041 ftprd1 where  RewardMethodId=1 and RewardId=100) ftprd1
  on ftprd1.TicketInternalKey=fth.TicketInternalKey   --and ftprd1.EntityId=fts.ItemId 
    left join report_data.[dbo].[PromotionHeader_PR] phpr 
	on phpr.PromotionHeaderId=ftprd1.PromotionId and phpr.MatrixMemberId=@MatrixMemberId
	left join  [report_data].[dbo].item_cat  item    on item.MainItemId=ftprd1.EntityId  and item.MatrixMemberId=@MatrixMemberId  
	left join    [Loyalty_Shell_1].[dbo].[CRM_Member] cm  on cp.BuyingUnitInternalKey=cm.BuyingUnitInternalKey
			 left join   report_data.[dbo].[v_get_reg_compAndStore]   s   on s.BuyingUnitInternalKey=cm.BuyingUnitInternalKey 
			 and   s.MatrixMemberId=cp.MatrixMemberId --首次注册油站
--left join RetailCode_MP  rc on rc.MatrixMemberId=cp.MatrixMemberId
  where fth.CreatedDate>=convert(date,@createdDate,120)   and  fth.CreatedDate<convert(date,@createDateNextday,120)   
     	 and phpr.PromotionHeaderId is not null
		  --and      rc.RetailerId=@retailerID
		  and      ftc.RetailerId=@retailerID
		  and s.comp  is not null  
    order by fth.CreatedDate';
	set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_pre);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
 	set @sql_text = replace(@sql_text,'@RetailerId' ,@RetailerId);
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
	set @sql_text = replace(@sql_text,'@CreatedDate',''''+@CreatedDate+'''');
	set @sql_text = replace(@sql_text,'@createDateNextday',''''+@createDateNextday+'''');
	print @sql_text;
	exec(@sql_text);
	set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_cur);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
 	set @sql_text = replace(@sql_text,'@RetailerId' ,@RetailerId);
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
	set @sql_text = replace(@sql_text,'@CreatedDate',''''+@CreatedDate+'''');
	set @sql_text = replace(@sql_text,'@createDateNextday',''''+@createDateNextday+'''');
	select @sql_text
	exec(@sql_text);
	
	 

------------discount------------------------


   end;





GO
