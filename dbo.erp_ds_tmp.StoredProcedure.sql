USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[erp_ds_tmp]    Script Date: 1/19/2022 9:01:17 AM ******/
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
CREATE  PROCEDURE [dbo].[erp_ds_tmp]
	 @businessDate varchar(10)='2017-03-01'   --yyyy-mm-dd
	AS
BEGIN
   
		 		 
		 declare @bal int =50; --per 20  point  for 1 rmb
    declare @tableDate_cur varchar(6) ,@tableDate_pre varchar(6) 
	,@atd_Server nvarchar(max) ='ATD_Shell'		
	,@ServerHost nvarchar(max)='HOST_Shell_1'
	,@loyalty_server varchar(max)='Loyalty_Shell_prod'
	,@sql_text  nvarchar(max)
	,@sql_text_org nvarchar(max)
	, @MatrixMemberId int=1

	  	 
	set @TableDate_cur=SUBSTRING(REPLACE(@businessDate,'-',''),1,6) --设置年月
	set @TableDate_pre=SUBSTRING(REPLACE(convert( varchar,dateadd(month,-1,@businessDate),120),'-',''),1,6) --设置年月 数据前一个月
		      
--R1-交易明细表 -- 油站积分发放：可以到单个商品
-- insert tran_detail_reward_point
 
truncate  table    report_data.[dbo].[DS_R1_tran]  
 --where business_date >=@createDate_begin   and business_date<=@business_end
    --    and   create_date>= @createDate_begin
	--	 and   create_date <@createDate_end                   ;
 set @sql_text_org=N' insert into  report_data.[dbo].[DS_R1_tran] (
            [member_card_no]              --1
		    ,member_reg_comp_code          --2.0
           , member_reg_comp				  --2
            ,member_reg_store_code         --3.0
           , member_reg_store              --3
          ,  reg_time                      --3.1
          ,  legal_code                    --6
         ,   legal_name                    --6.1
          ,  store_code                    --4 
         ,   store_name                    --5
           ,[city]						--7
           ,[cashierid]					--8
           ,[transaction_no]			--9
           ,[business_date]				--10
           ,[transaction_date]			--11
           ,[transaction_time]			--12
           ,[posid]						--13
           ,[item_cat]					--14
		    ,[item_cat_mid_cod]					--14.1
           ,[item_cat_mid]				--15
           ,[item_code]					--16
           ,[item_name]					--17
           ,[quantity]					--18
           ,[due_amount]				--19
           ,[discount_amount]			--20
           ,[amount]					--21
		   ,create_date                --22
      
	)			
 select cp.ClubCardId          --1会员号码

,s.compid    compid            --2.0
,s.comp      regcomp           --2会员注册公司
,s.storeid   storeid           --3.0会员注册油站     
,s.storename  regstore         --3会员注册默认油站
,convert(varchar(10),s.UpdatedDate,120)  --3.1注册时间
,store.comp as sal_com                                  --6公司代码
,store.compid as sal_com_id                             --6.1公司代码
  ,store.storeid                 --4 油站代码
 ,store.storename as stor       -- 5油站名称
 
 ,store.city   city                                          --7城市
 , ftc.CashierId                         --8Cashier ID
 ,fth.TranId                              --9交易流水号
 ,convert(varchar(10),ftc.BusinessDate ,120) BusinessDate                   --10营业日
 ,convert(varchar(10),fth.StartDateTime,120)  trandate                  --11交易日期
 ,CONVERT(varchar(100), fth.StartDateTime, 8)      trantime           --12交易时间,
 ,ftc.TillId                                                                --13POS ID
, item.firsttype                     --14商品类型
 ,item.midtypeCode
 , item.midtype                                     --15商品中类
   
 ,   fts.ItemId                               --16SKU
  ,  item.FullName                        --17商品
	--,fts.Price,                               --18
	,fts.Qty as qty ,                                  --18数量
	fts.amount as amount ,                           --19应收金额
     isnull(ftprd.rewardValue,0)  rewardValue              --20优惠金额
	 ,fts.amount-isnull(ftprd.rewardValue,0) as netamount  --21实付金额
	 ,convert(varchar,fth.CreatedDate,120)
	 
	
     from   
		  [ATD_Shell].dbo.FO_TranHeader201704 fth 
	 		 
		  
		  inner  join [ATD_Shell].[dbo].[FO_TranCollection] ftc
		 
on ftc.CollectionInternalKey=fth.CollectionInternalKey
 inner  join  [report_data].[dbo].store_gs store on store.storeid=ftc.storeid and  store.MatrixMemberId=@MatrixMemberId
   left join  Loyalty_Shell_1. [dbo].[CRM_POSTran] cp 
    on cp.TranId=fth.TranId and cp.PosDateTime=ftc.BusinessDate and cp.StoreInternalKey=store.StoreInternalKey
	   and cp.MatrixMemberId=@MatrixMemberId  and cp.PosId=ftc.TillId
	inner join  ( select  fts1.TicketInternalKey,fts1.ItemId,sum(fts1.Amount) as  amount,sum(fts1.qty) as qty  from  
	  [ATD_Shell].dbo.FO_TranSale201704 fts1   group  by  fts1.TicketInternalKey,fts1.ItemId ) fts
	on fts.TicketInternalKey=fth.TicketInternalKey
		left join (select    TicketInternalKey,		    sum(ftprd1.RewardValue)    as RewardValue , entityid
		 
  from  report.dbo.FO_TranPromotionRewardApportionment112 ftprd1 -- where RewardMethodId=4 
     group by  TicketInternalKey,entityid ) ftprd

	on ftprd.TicketInternalKey=fts.TicketInternalKey and ftprd.EntityId=fts.ItemId 
 	left join  [report_data].[dbo].item_cat  item 
	on item.MainItemId=fts.ItemId   and item.MatrixMemberId=@MatrixMemberId
	 left join    [Loyalty_Shell_1].[dbo].[CRM_Member] cm  on cp.BuyingUnitInternalKey=cm.BuyingUnitInternalKey
	
	 left join   report_data.[dbo].[v_get_reg_compAndStore]   s   on s.BuyingUnitInternalKey=cm.BuyingUnitInternalKey
	  and   s.MatrixMemberId=@MatrixMemberId    --首次注册油站 --首次注册油站

  where
     
 ftc.BusinessDate=@businessDate    
    order by fth.CreatedDate';
	
	set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_pre);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
--	set @sql_text = replace(@sql_text,'@createDate_begin',''''+@createDate_begin+'''');
--	set @sql_text = replace(@sql_text,'@createDate_end',''''+@createDate_end+'''');
--	set @sql_text = replace(@sql_text,'@business_end',''''+@business_end+'''');
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
	set @sql_text = replace(@sql_text,'@businessDate',''''+@businessDate+'''');
	print '1'
	--exec(@sql_text);
	print '2'
	set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_cur);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
--	set @sql_text = replace(@sql_text,'@createDate_begin',''''+@createDate_begin+'''');
--	set @sql_text = replace(@sql_text,'@createDate_end',''''+@createDate_end+'''');
--	set @sql_text = replace(@sql_text,'@business_end',''''+@business_end+'''');
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
    set @sql_text = replace(@sql_text,'@businessDate',''''+@businessDate+'''');

--	exec(@sql_text);


	

 -- print @tran_detail_reward_point_sql;
--  insert into  report_data.[dbo].[tran_detail_reward_point]  exec @tran_detail_reward_point_sql

--  R1_1  discount table 

truncate  table report_data.[dbo].[DS_R1_1_tran_discount] ;
 set @sql_text_org=N'insert into  report_data.[dbo].[DS_R1_1_tran_discount] (
            [member_card_no]              --1
			, [member_reg_comp_code]          --2.0
            ,member_reg_comp				  --2
          ,  member_reg_store_code         --3.0
          ,  member_reg_store              --3
          ,  legal_code                    --6
          ,  legal_name                    --6.1
          ,  store_code                    --4 
          ,  store_name                    --5
           ,[city]						--7
           ,[cashierid]					--8
           ,[transaction_no]			--9
           ,[business_date]				--10
           ,[transaction_date]			--11
           ,[transaction_time]			--12
           ,[posid]						--13
           ,[item_cat]					--14
		    ,item_cat_mid_cod           --14.1
           ,[item_cat_mid]				--15
           ,[item_code]					--16
           ,[item_name]					--17
           ,[discount_amount]			--20
         
           ,[promtion_id]				--24
           ,[promtion_group]			--25
		   ,promtion_ref                --26
		   ,create_date                 --27
		   )
select cp.ClubCardId          --1会员号码
,s.compid    compid            --2.0
,s.comp      regcomp           --2会员注册公司
,s.storeid   storeid           --3.0会员注册油站     
,s.storename  regstore         --3会员注册默认油站
,store.compid as sal_com_id                                  --6公司代码
,store.comp as sal_com                             --6.1公司代码
  ,store.storeid                 --4 油站代码
 ,store.storename as stor       -- 5油站名称
 
 ,store.city   city                                          --7城市
 , ftc.CashierId                         --8Cashier ID
 ,fth.TranId                              --9交易流水号
 ,convert(varchar(10),ftc.BusinessDate ,120) BusinessDate                   --10营业日
 ,convert(varchar(10),fth.StartDateTime,120)  trandate                  --11交易日期
 ,CONVERT(varchar(100), fth.StartDateTime, 8)      trantime           --12交易时间,
 ,ftc.TillId                                                                --13POS ID
, item.firsttype                     --14商品类型
,item.midtypeCode
 , item.midtype                                     --15商品中类
   
 ,   ftprd.EntityId                               --16SKU
  ,  item.FullName                        --17商品
	--,fts.Price,                               --18
	--,fth.thbz*fts.Qty as qty ,                                  --18数量
	--fth.thbz*fts.Amount as amount ,                           --19应收金额
    , isnull(ftprd.rewardValue,0)  rewardValue              --20优惠金额
	 --,fth.thbz*fts.amount-isnull(ftprd.rewardValue,0) as netamount  --21实付金额
	-- ,fth.thbz*ftprd1.RewardValue as RewardvaluePoint        --22获得积分
	--, fth.thbz*ftprd1.RewardValue/6   as reward_amount                            --23积分发放金额
	 ,ftprd.PromotionId                                            --24促销id
	 ,phpr.PromotionGroupId                                 --25促销组
	 ,substring(phpr.ExternalReferenceID,1,8)                             --26 外部促销id
	 ,convert(varchar,fth.CreatedDate,120)                  --27 上传日期
	--  ,ftprd1.PromotionId as pointPromotionId        --获得积分促销id
 from 
		  [ATD_Shell].dbo.FO_TranHeader201704 fth
	 
		
		  
		  inner  join [ATD_Shell].[dbo].[FO_TranCollection] ftc
		 
on ftc.CollectionInternalKey=fth.CollectionInternalKey
 inner  join  [report_data].[dbo].store_gs store on store.storeid=ftc.storeid and  store.MatrixMemberId=@MatrixMemberId
   left join  Loyalty_Shell_1. [dbo].[CRM_POSTran] cp 
    on cp.TranId=fth.TranId and cp.PosDateTime=ftc.BusinessDate and cp.StoreInternalKey=store.StoreInternalKey
	and  cp.MatrixMemberId=@MatrixMemberId
		left join ((select  distinct  TicketInternalKey, ftprd1.PromotionId ,    ftprd1.RewardValue   as RewardValue , entityid 
  from  [ATD_Shell].dbo.FO_TranPromotionRewardApportionment201704 ftprd1 where RewardMethodId=4) ) ftprd
	on ftprd.TicketInternalKey=fth.TicketInternalKey   --and ftprd.EntityId=fts.ItemId 

   inner join [Loyalty_Shell_1].[dbo].[PromotionHeader_PR] phpr 
	on phpr.PromotionHeaderId=ftprd.PromotionId  and  phpr.MatrixMemberId=@MatrixMemberId
	left join  [report_data].[dbo].item_cat  item 
	on item.MainItemId=ftprd.EntityId  and item.MatrixMemberId=@MatrixMemberId
	 left join    [Loyalty_Shell_1].[dbo].[CRM_Member] cm  on cp.BuyingUnitInternalKey=cm.BuyingUnitInternalKey
	
	 left join   report_data.[dbo].[v_get_reg_compAndStore]   s   on s.BuyingUnitInternalKey=cm.BuyingUnitInternalKey
	 and   s.MatrixMemberId=@MatrixMemberId  --首次注册油站


  where      ftc.BusinessDate=@businessDate     and phpr.externalReferenceId is   null


   
    order by fth.CreatedDate';
	set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_pre);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
	--set @sql_text = replace(@sql_text,'@createDate_begin',''''+@createDate_begin+'''');
	--set @sql_text = replace(@sql_text,'@createDate_end',''''+@createDate_end+'''');
	--set @sql_text = replace(@sql_text,'@business_end',''''+@business_end+'''');
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
    set @sql_text = replace(@sql_text,'@businessDate',''''+@businessDate+'''');
	--exec(@sql_text);
	set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_cur);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
	--set @sql_text = replace(@sql_text,'@createDate_begin',''''+@createDate_begin+'''');
	--set @sql_text = replace(@sql_text,'@createDate_end',''''+@createDate_end+'''');
	--set @sql_text = replace(@sql_text,'@business_end',''''+@business_end+'''');
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
set @sql_text = replace(@sql_text,'@businessDate',''''+@businessDate+'''');
--	exec(@sql_text);
	 
	
------------discount------------------------
----------------reward point---------------------
--truncate  table  report_data.[dbo].[DS_r1_2_tran_reward] 

set @sql_text_org=N'insert into  report_data.[dbo].[DS_r1_2_tran_reward] (
            [member_card_no]              --1
           , member_reg_comp_code          --2.0
           , member_reg_comp				  --2
           , member_reg_store_code         --3.0
           , member_reg_store              --3
           ,legal_name                      --6
           ,legal_code                   --6.1
           , store_code                    --4 
           , store_name                    --5
           ,[city]						--7
           ,[cashierid]					--8
           ,[transaction_no]			--9
           ,[business_date]				--10
           ,[transaction_date]			--11
           ,[transaction_time]			--12
           ,[posid]						--13
           ,[item_cat]					--14
		   ,item_cat_mid_code
           ,[item_cat_mid]				--15
           ,[item_code]					--16
           ,[item_name]					--17
           
           ,[reward_point]				--22
           ,[reward_amount]				--23
           ,[promtion_id]				--24
           ,[promtion_group]			--25
		   ,promtion_ref                --26
		   ,create_date                  --27
		   )
 select cp.ClubCardId          --1会员号码

,s.compid    compid            --2.0
,s.comp      regcomp           --2会员注册公司
,s.storeid   storeid           --3.0会员注册油站     
,s.storename  regstore         --3会员注册默认油站
,store.comp as sal_com                                  --6公司
,store.compid as sal_com_id                             --6.1公司代码
  ,store.storeid                 --4 油站代码
 ,store.storename as stor       -- 5油站名称
 
 , store.city    city                                          --7城市
 , ftc.CashierId                         --8Cashier ID
 ,fth.TranId                              --9交易流水号
 ,convert(varchar(10),ftc.BusinessDate ,120) BusinessDate                   --10营业日
 ,convert(varchar(10),fth.StartDateTime,120)  trandate                  --11交易日期
 ,CONVERT(varchar(100), fth.StartDateTime, 8)      trantime           --12交易时间,
 ,ftc.TillId                                                                --13POS ID
, item.firsttype                     --14商品类型
,item.midtypeCode
 , item.midtype                                     --15商品中类
   
 ,   ftprd1.EntityId                              --16SKU
  ,  item.FullName                        --17商品
	
	 ,ftprd1.RewardValue as RewardvaluePoint        --22获得积分
	, round(ftprd1.RewardValue/@bal,2)   as reward_amount                            --23积分发放金额
	 ,ftprd1.PromotionId                                            --24促销id
	 ,phpr.PromotionGroupId                                 --25促销组
	 
	 ,substring(phpr.ExternalReferenceID,1,8)                             --26 外部促销id
	 ,convert(varchar(10),fth.CreatedDate,120)                  --27 上传日期

   from   
		   [ATD_Shell].dbo.FO_TranHeader201704 fth
			  inner  join [ATD_Shell].[dbo].[FO_TranCollection] ftc
		 
on ftc.CollectionInternalKey=fth.CollectionInternalKey
 inner  join  [report_data].[dbo].store_gs store on store.storeid=ftc.storeid and store.MatrixMemberId=@MatrixMemberId
   left join  Loyalty_Shell_1. [dbo].[CRM_POSTran] cp 
    on cp.TranId=fth.TranId and cp.PosDateTime=ftc.BusinessDate and cp.StoreInternalKey=store.StoreInternalKey
	  and  cp.MatrixMemberId=@MatrixMemberId and cp.PosId=ftc.TillId
	--inner join [ATD_Shell].dbo.FO_TranSale201704 fts
---	on fts.TicketInternalKey=fth.TicketInternalKey
		
  inner join (select  distinct  TicketInternalKey, ftprd1.PromotionId ,ftprd1.RewardValue , entityid 
  from  FO_TranPromotionRewardApportionment07 ftprd1   --where  RewardMethodId=1 and RewardId=100
  ) ftprd1
  on ftprd1.TicketInternalKey=fth.TicketInternalKey   --and ftprd1.EntityId=fts.ItemId 
    left join [Loyalty_Shell_1].[dbo].[PromotionHeader_PR] phpr 
	on phpr.PromotionHeaderId=ftprd1.PromotionId and phpr.MatrixMemberId=@MatrixMemberId
	left join  [report_data].[dbo].item_cat  item    on item.MainItemId=ftprd1.EntityId  and item.MatrixMemberId=@MatrixMemberId  
	left join    [Loyalty_Shell_1].[dbo].[CRM_Member] cm  on cp.BuyingUnitInternalKey=cm.BuyingUnitInternalKey
			 left join   report_data.[dbo].[v_get_reg_compAndStore]   s   on s.BuyingUnitInternalKey=cm.BuyingUnitInternalKey 
			 and   s.MatrixMemberId=@MatrixMemberId --首次注册油站


  where ftc.BusinessDate=@businessDate   
     --	 and phpr.PromotionHeaderId is not null  
    order by fth.CreatedDate';
	set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_pre);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
--	set @sql_text = replace(@sql_text,'@createDate_begin',''''+@createDate_begin+'''');
--	set @sql_text = replace(@sql_text,'@createDate_end',''''+@createDate_end+''''); 
--	set @sql_text = replace(@sql_text,'@business_end',''''+@business_end+'''');
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
	set @sql_text = replace(@sql_text,'@businessDate',''''+@businessDate+'''');
--	print @sql_text;
--	exec(@sql_text);
	set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_cur);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
--	set @sql_text = replace(@sql_text,'@createDate_begin',''''+@createDate_begin+'''');
--	set @sql_text = replace(@sql_text,'@createDate_end',''''+@createDate_end+'''');
--	set @sql_text = replace(@sql_text,'@business_end',''''+@business_end+'''');
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
	set @sql_text = replace(@sql_text,'@businessDate',''''+@businessDate+'''');
	--print @sql_text;
	exec(@sql_text);
	
	 
------------------------------------
 --R2-油站积分兑换 
 -- set @redemption_point_sql=
truncate  table report_data. [dbo].DS_R2_redemption_point
 --where business_date >=@createDate_begin   and business_date<=@business_end
 --       and   create_date>= @createDate_begin
--		 and   create_date <@createDate_end ;
set  @sql_text_org=N'insert into report_data. [dbo].DS_R2_redemption_point
          ([member_card_no]            --1
          , member_reg_comp_code          --2.0
          ,  member_reg_comp				  --2
          ,  member_reg_store_code         --3.0
          ,  member_reg_store              --3
          ,  legal_code                    --6
          ,  legal_name                    --6.1
          ,  store_code                    --4 
          ,  store_name                    --5
           ,[city]                     --7
           ,[cashier_id]               --8
           ,[transaction_no]           --9
           ,[business_date]            --10
           ,[transaction_date]         --11
           ,[transaction_time]         --12
           ,[posid]                    --13
           ,[item_cat]                 --14
           ,[item_cat_mid]             --15
            ,item_cat_mid_name        --15.1
           ,[item]                     --16
		   ,[item_name]                --17
           ,[quantity]                 --18
           ,[redemption_point_q]       --19
		   ,[redemption_point_amount]  --20
		    ,redemption_point_je --19.1  积分折算金额
           
   		   ,redem_ce  -- 20.1差额
           ,[promotion_id]             --21
           ,[promotion_group]         --22
		    ,promtion_ref                --23
		   ,create_date                  --24
		   )
select   cp.ClubCardId,                                  --1会员号码

 s.compid    compid            --2.0
,s.comp      regcomp           --2会员注册公司
,s.storeid   storeid           --3.0会员注册油站     
,s.storename  regstore         --3会员注册默认油站
,store.compid as sal_com_id                                   --6公司代码
,store.comp as sal_com                             --6.1公司代码
  ,store.storeid                 --4 油站代码
 ,store.storename as stor       -- 5油站名称
 ,  store.city   as city,                        --7城市
    ftc.CashierId ,                             --8cashierid
	  fth.TranId  ,                             --9交易流水号
  convert(varchar(10), ftc.BusinessDate,120) businessDate,        --10营业日
   convert(varchar(10),ftc.createddate,120) trandate,             --11交易日期
   convert(varchar(8),ftc.createddate,8)  trantime,               --12交易时间
   ftc.TillId   posid   ,                                      --13
   item.firsttype,                                  --14商品类型
  item.midtypeCode,                                 --15 商品中类
 item.midtype,                                      --15.1 商品中类
 item.mainitemid,                                   --16
  item.FullName,							        -- 17 商品  
  ftprd.RewardedQty,			     				            --18数量
 cast(  ftprd.rewardValue/ftprds.RewardValue*ftpma.AdjustmentValue  as decimal(10,2) )-ftprds.RewardValue*@bal    Redemption_quantity, --19                  --19积分兑换数量 
 cast( ftprd.rewardValue/ftprds.RewardValue*ftpma.AdjustmentValue/@bal  as decimal(10,2))
 
   as redemption_point_je  , --19.1  积分折算金额
 cast( ftprd.rewardValue as decimal(10,2))  redemption ,           --20积分抵扣金额
cast (-1*( ftprd.rewardValue-ftprd.rewardValue/ftprds.RewardValue*ftpma.AdjustmentValue /@bal ) as decimal(10,2))
   as    redem_ce ,  -- 20.1差额
	 ftprd.PromotionId,                                  --21
	 phpr.ExternalGroupId                             --22
	 ,substring(phpr.ExternalReferenceID,1,8)                          --23 外部促销id
	 ,convert(varchar,cp.CreatedAt,120)                 --24 上传日期

  '
  set @sql_text_org= @sql_text_org+'     from  Loyalty_Shell_1. [dbo].[CRM_POSTran] cp
    inner join   [report_data].[dbo].store_gs  store1 on store1.StoreInternalKey=cp.StoreInternalKey  and cp.MatrixMemberId=@MatrixMemberId
    and store1.MatrixMemberId=@MatrixMemberId   
	 inner  join [ATD_Shell].[dbo].[FO_TranCollection] ftc  on ftc.BusinessDate=cp.PosDateTime  and store1.storeid=ftc.StoreId
 	  inner join	   [ATD_Shell].dbo.FO_TranHeader201704    fth
    on fth.CollectionInternalKey=ftc.CollectionInternalKey  and fth.TranId=cp.TranId  
inner join (
    select   ftprd1.TicketInternalKey, ftprd1.PromotionId ,sum(ftprd1.RewardValue) RewardValue  
    from  [ATD_Shell].[dbo].[FO_TranPromotionRewardApportionment201704] ftprd1  
	   where RewardMethodId in (5,3) 
	   group by ftprd1.TicketInternalKey, ftprd1.PromotionId having sum(ftprd1.RewardValue)<>0 ) ftprds
	   on ftprds.TicketInternalKey=fth.TicketInternalKey
	inner join      [ATD_Shell].[dbo].[FO_TranPromotionRewardApportionment201704] ftprd  
	
	-- on ftprd.TicketInternalKey=fth.TicketInternalKey  
	 on  ftprds.TicketInternalKey=ftprd.TicketInternalKey and ftprd.PromotionId=ftprds.PromotionId
	  and ftprd.RewardMethodId in (5,3) 
inner  join report_data..check_loaytyPoint clp on clp.loytranid=fth.TranId and clp.posid=ftc.TillId 
	inner join   [ATD_Shell].[dbo].[FO_TranPromotionMemberAccount201704] ftpma 
	on ftprds.TicketInternalKey=ftpma.TicketInternalKey and ftpma.PromotionId=ftprds.PromotionId'

 set @sql_text_org=@sql_text_org+'    left join report_data.[dbo].[PromotionHeader_PR] phpr 	on phpr.PromotionHeaderId=ftprd.PromotionId  and phpr.MatrixMemberId=@MatrixMemberId
	left join  [report_data].[dbo].item_cat  item 	on item.MainItemId=ftprd.EntityId   and item.MatrixMemberId=@MatrixMemberId 
	 left join    [Loyalty_Shell_1].[dbo].[CRM_Member] cm  on cp.BuyingUnitInternalKey=cm.BuyingUnitInternalKey
  	 left join   report_data.[dbo].[v_get_reg_compAndStore]   s   on s.BuyingUnitInternalKey=cm.BuyingUnitInternalKey
	 and   s.MatrixMemberId=@MatrixMemberId  --首次注册油站
  left join [report_data].[dbo].store_gs  store on cp.StoreInternalKey=store.StoreInternalKey
   and store.MatrixMemberId=@MatrixMemberId  and cp.MatrixMemberId=store.MatrixMemberId
  where   
 ftc.BusinessDate=@businessDate   
 
    and cp.MatrixMemberId=1
   and cp.MatrixMemberId=@MatrixMemberId
   and cast (-1*( ftprd.rewardValue-ftprd.rewardValue/ftprds.RewardValue*ftpma.AdjustmentValue /@bal ) as decimal(10,2))
  <>0
  order by cp.CreatedAt';
 set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_pre);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);

--	set @sql_text = replace(@sql_text,'@createDate_begin',''''+@createDate_begin+'''');
--	set @sql_text = replace(@sql_text,'@createDate_end',''''+@createDate_end+'''');
	--set @sql_text = replace(@sql_text,'@business_end',''''+@business_end+'''');
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
	   set @sql_text = replace(@sql_text,'@businessDate',''''+@businessDate+'''');

--	print @sql_text
--	exec(@sql_text);
	set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_cur);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);

--	set @sql_text = replace(@sql_text,'@createDate_begin',''''+@createDate_begin+'''');
--	set @sql_text = replace(@sql_text,'@createDate_end',''''+@createDate_end+'''');
--	set @sql_text = replace(@sql_text,'@business_end',''''+@business_end+'''');
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
   set @sql_text = replace(@sql_text,'@businessDate',''''+@businessDate+'''');
   print @sql_text
	--exec(@sql_text);
  
  

--- R9-point detail list related to central adjustment 中央积分发放
--insert into adjust_center_point
--truncate  table report_data.[dbo].[DS_r9_adjust] 
--where business_date >=@createDate_begin   and business_date<=@business_end
 --       and   create_date>= @createDate_begin
--		 and   create_date <@createDate_end 
set @sql_text_org=N'INSERT INTO report_data.[dbo].[DS_r9_adjust]
           ([member_card_no]		--1
           ,[member_reg_comp]		--2
		   ,[member_reg_comp_code] --2.1
           ,[member_reg_store]		--3
           ,[store_id]				--4
           ,[transaction_no]		--5
           ,[business_date]			--6
           ,[pos_id]				--7
           ,[reason_adjust]			--8
		   ,reason_adjust_code      --8.1
           ,[number_awarding]		--9
           ,[number_redemption_amount] --10
           ,date_expired				--11
          ,[number_awarding_amount]
             ,create_date
		   )   --12积分发行金额

select  cm.externalmemberkey     --1会员号码
,  s.comp   as regcomp                  --2会员注册公司name
, s.compid  as regcompid                          --2.1
, s.storename   regstore                       --3会员默认油站

, s.storeid   as storeid                                    --4油站代码
,  cp.TranId  --paa.PosTranInternalKey                  --5交易流水号
,convert(varchar(10),paa.PosDateTime,120)                           --6营业日
,cp.PosId                                         --7posid
 ,isnull(gd.Value,purc.ReasonDescription)               --8积分调整原因
 ,purc.ReasonCode
 ,   paa.EarnValue-paa.RedeemValue  EarnValue  --9积分发行数量
 , 0 --redempton        ---10积分兑换数量
 ,convert(varchar(10),paa.ExpirationDate,120)                       --11积分过期日期
,round((paa.EarnValue-paa.RedeemValue) /@bal,2)  as awarding_amount      --12积分发行金额
  ,convert(varchar(10),paa.PosDateTime,120) 
     from      Loyalty_Shell_1. [dbo].CRM_POSAccountsActivity  paa
    left join Loyalty_Shell_1.[dbo].[CRM_PointsUpdateReasonCodes] purc on paa.ReasonCode=purc.ReasonCode
	left join MP_Shell.dbo.GeneralDictionary gd on gd.EntryId=purc.ReasonDescription and gd.LanguageId=8
 
		 left join    [Loyalty_Shell_1].[dbo].[CRM_Member] cm  on paa.BuyingUnitInternalKey=cm.BuyingUnitInternalKey
	   left join   Loyalty_Shell_1. [dbo].[CRM_POSTran] cp on cp.POSTranInternalKey=paa.PosTranInternalKey
     left join  [Loyalty_Shell_1].dbo.[CRM_BuyingUnit] cbu on paa.BuyingUnitInternalKey=cbu.BuyingUnitInternalKey
	
    	 left join   report_data.[dbo].[v_get_reg_compAndStore]   s   on s.BuyingUnitInternalKey=cm.BuyingUnitInternalKey
		 and   s.MatrixMemberId=@MatrixMemberId  --首次注册油站


		   
 where
  ((posid=-66 ) or  (posid=-99 ))  and paa.ReasonCode<>7   --and paa.ReasonCode<>7 不统计b2c的积分 
 -- and c1.compid is not null 
 and paa.AccountInternalKey=2 --使用100的账号 20170926
  and  cp.PosDateTime=@businessDate   and cp.MatrixMemberId=@MatrixMemberId   
 order by cp.PosDateTime';

 set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@TableDate_cur);
--	set @sql_text = replace(@sql_text,'@createDate_begin',''''+@createDate_begin+'''');
--	set @sql_text = replace(@sql_text,'@createDate_end1',''''+@createDate_end1+'''');
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
	 set @sql_text = replace(@sql_text,'@businessDate',''''+@businessDate+'''');
	  set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);

	print @sql_text;
	--exec(@sql_text);
	--delete report_data.[dbo].[DS_r9_adjust]  where member_reg_comp_code is null ;
	
delete from report_data.[dbo].[DS_r9_adjust]  where member_reg_comp_code is null or member_reg_comp is null 

  
  

   end;



GO
