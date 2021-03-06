USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[est_hk]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/****** Object:  StoredProcedure [dbo].[est]    Script Date: 2017/3/2 18:01:20 ******/

-- =============================================
-- Author:		<Author,,Name>
----rewardmethodid  (1-MemberAccount,2-Voucher,3-Coupon,4-Discount,5-MOP,6-Target Message,8=Decrease Member Account)
--Reardmethodid was descripted in  stp_Upload_Insert_TranPromotionRewardApportionment  Create date: <Create Date,,>
-- Description:	<Description,,>
-- EXEC est_hk  '2021-11-15'
 
--2021-11-02 香港迁移，优化部分程序，独立R报表程序
--v1.0

-- =============================================
CREATE PROCEDURE [dbo].[est_hk]
	 @createDate varchar(10)='2017-03-01'   --yyyy-mm-dd

	AS
BEGIN
     declare  @businessDate varchar(10)= @createDate
       declare  @business_end   varchar(10);
	  declare @createdDateNextday varchar(10)= dateadd( day,1,convert(date,@createdate,120))	
		declare @MatrixMemberId int
	  	 set @business_end=@businessDate;
	   
	  
	 
	    declare   @table VARCHAR(max) ='promotion_list'
		  ,@Server VARCHAR(max)   ='Loyalty_Shell_1.dbo.'
		  ,@FilePath NVARCHAR(400)=  'C:\Retalix\HQ\uploadfile_host\a\'  
		  ,@Expoprtfilename nvarchar(300)
		  ,@bal float =50.00 --per 50  point  for 1 rmb   201801102
		  ,@RetailerId varchar(10) 

		   select @MatrixMemberId=MatrixMemberId,@RetailerId=RetailerId
		   from  RetailCode_MP rcmp     where rcmp.RetailValue='2'   ;

 
    declare @tableDate_cur varchar(6) ,@tableDate_pre varchar(6) 
	,@atd_Server nvarchar(max) ='ATD_Shell'		
	,@ServerHost nvarchar(max)='HOST_Shell_1'
	,@loyalty_server varchar(max)='Loyalty_Shell_1'
	,@sql_text  nvarchar(max)
	,@sql_text_org nvarchar(max)
		,@sql_text_org1 nvarchar(max)
	select @atd_Server=c.paraValue0   from dbo.param_config c  where c.paraName='atd_Server';
	select @ServerHost=c.paraValue0   from dbo.param_config c  where c.paraName='ServerHost';
	select @loyalty_server=c.paraValue0   from dbo.param_config c  where c.paraName='loyalty_server';

	select @FilePath=erc.ExtractLocalPath  from extractReportConfig erc where erc.MatrixMemberId=@MatrixMemberId
	print @filepath;
	set @TableDate_cur=SUBSTRING(REPLACE(@createDate,'-',''),1,6) --设置年月
	set @TableDate_pre=SUBSTRING(REPLACE(convert( varchar,dateadd(month,-1,@createDate),120),'-',''),1,6) --设置年月 数据前一个月

		
	
	
			      
			      
--R1-交易明细表 -- 油站积分发放：可以到单个商品
-- insert tran_detail_reward_point
 
delete report_data.[dbo].[R1_tran] ;
 set @sql_text_org=N' 
 select    TicketInternalKey,		    sum(ftprd1.RewardValue)    as RewardValue , entityid
		 into #ftprd1
		 
  from  [ATD_Shell].dbo.FO_TranPromotionRewardApportionment201704 ftprd1 where RewardMethodId=4 
     group by  TicketInternalKey,entityid 
	 create index fptr on #ftprd1(ticketInternalkey)
 insert into  report_data.[dbo].[R1_tran] (
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
		left join  #ftprd1 ftprd

	on ftprd.TicketInternalKey=fts.TicketInternalKey and ftprd.EntityId=fts.ItemId 
 	left join  [report_data].[dbo].item_cat  item 
	on item.MainItemId=fts.ItemId and item.MatrixMemberId=@MatrixMemberId  
	 left join    [Loyalty_Shell_1].[dbo].[CRM_Member] cm  on cp.BuyingUnitInternalKey=cm.BuyingUnitInternalKey


    
	 left join   report_data.[dbo].[v_get_reg_compAndStore]   s   on s.BuyingUnitInternalKey=cm.BuyingUnitInternalKey
	  and  s.MatrixMemberId=@MatrixMemberId  --首次注册油站

  where 	 
	 fth.CreatedDate>=convert(date,@createDate,120)   and  fth.CreatedDate<convert(date,@createdDateNextday,120) 
	                                 
  ';

	set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_pre);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
	set @sql_text = replace(@sql_text,'@createDate',''''+@createDate+'''');
 	set @sql_text = replace(@sql_text,'@createdDateNextday',''''+@createdDateNextday+'''');

	 	
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
	

--if OBJECT_ID('tempdb..#ftprd1') is not null 
--  drop  table #ftprd1
	exec(@sql_text);
	set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_cur);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
	set @sql_text = replace(@sql_text,'@createDate',''''+@createDate+'''');
 	set @sql_text = replace(@sql_text,'@createdDateNextday',''''+@createdDateNextday+'''');
 
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
--if OBJECT_ID('tempdb..#ftprd1') is not null 
--  drop  table #ftprd1
	exec(@sql_text);


	print @table
 set  @table='R1_tran';
set  @Expoprtfilename=@filepath+@table+'\'+@table+@createDate+'-'+@business_end+'.csv';
 
exec  report_data.[dbo].est_export_cvs @table,@Server,@Expoprtfilename;	

 -- print @tran_detail_reward_point_sql;
--  insert into  report_data.[dbo].[tran_detail_reward_point]  exec @tran_detail_reward_point_sql

--  R1_1  discount table 
if OBJECT_ID('tempdb..#ftprd1') is not null 
  drop  table #ftprd1

  delete report_data.[dbo].[R1_1_tran_discount] ;
 set @sql_text_org=N'
 
 select  distinct  TicketInternalKey, ftprd1.PromotionId ,    ftprd1.RewardValue   as RewardValue , entityid into  #ftprd1 
  from  [ATD_Shell].dbo.FO_TranPromotionRewardApportionment201704 ftprd1 where RewardMethodId=4 
   create index fptr on #ftprd1(ticketInternalkey)
 insert into  report_data.[dbo].[R1_1_tran_discount] (
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
	 ,phpr.ExternalGroupId --phpr.PromotionGroupId                                 --25促销组
	 ,substring(phpr.ExternalReferenceID,1,8)                             --26 外部促销id
	 ,convert(varchar,fth.CreatedDate,120)                  --27 上传日期
	--  ,ftprd1.PromotionId as pointPromotionId        --获得积分促销id
 from 
		  [ATD_Shell].dbo.FO_TranHeader201704 fth
	 
		
		  
		  inner  join [ATD_Shell].[dbo].[FO_TranCollection] ftc
		 
on ftc.CollectionInternalKey=fth.CollectionInternalKey
 inner  join  [report_data].[dbo].store_gs store on store.storeid=ftc.storeid and store.MatrixMemberId=@MatrixMemberId
   left join  Loyalty_Shell_1. [dbo].[CRM_POSTran] cp 
    on cp.TranId=fth.TranId and cp.PosDateTime=ftc.BusinessDate and cp.StoreInternalKey=store.StoreInternalKey
	and  cp.MatrixMemberId=@MatrixMemberId
--	inner join [ATD_Shell].dbo.FO_TranSale201704 fts
--	on fts.TicketInternalKey=fth.TicketInternalKey
		left join #ftprd1 ftprd
	on ftprd.TicketInternalKey=fth.TicketInternalKey   --and ftprd.EntityId=fts.ItemId 
  -- left join (select  distinct  TicketInternalKey, ftprd1.PromotionId ,ftprd1.RewardValue , entityid 
--  from  [ATD_Shell].dbo.FO_TranPromotionRewardApportionment201704 ftprd1 where RewardMethodId=1) ftprd1
 -- on ftprd1.TicketInternalKey=fts.TicketInternalKey  --and ftprd1.EntityId=fts.ItemId 
   inner join report_data.[dbo].[PromotionHeader_PR] phpr 
	on phpr.PromotionHeaderId=ftprd.PromotionId  and  phpr.MatrixMemberId=@MatrixMemberId
	left join  [report_data].[dbo].item_cat  item 
	on item.MainItemId=ftprd.EntityId and item.MatrixMemberId=@MatrixMemberId
	 left join    [Loyalty_Shell_1].[dbo].[CRM_Member] cm  on cp.BuyingUnitInternalKey=cm.BuyingUnitInternalKey
	
	    left join   report_data.[dbo].[v_get_reg_compAndStore]   s   on s.BuyingUnitInternalKey=cm.BuyingUnitInternalKey 
		and s.MatrixMemberId=@MatrixMemberId--首次注册油站


  where  fth.CreatedDate>=convert(date,@createDate,120)   and  fth.CreatedDate<convert(date,@createdDateNextday,120) ';
	set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_pre);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
	set @sql_text = replace(@sql_text,'@createDate',''''+@createDate+'''');
 	set @sql_text = replace(@sql_text,'@createdDateNextday',''''+@createdDateNextday+'''');
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
	set @sql_text = replace(@sql_text,'@businessDate',''''+@businessDate+'''');
	exec(@sql_text);
	if OBJECT_ID('tempdb..#ftprd1') is not null 
  drop  table #ftprd1
	set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_cur);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
	set @sql_text = replace(@sql_text,'@createDate',''''+@createDate+'''');
 	set @sql_text = replace(@sql_text,'@createdDateNextday',''''+@createdDateNextday+'''');
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
	set @sql_text = replace(@sql_text,'@businessDate',''''+@businessDate+'''');
	exec(@sql_text);
	 
	set  @table='R1_1_tran_discount';
    print @table
	set  @Expoprtfilename=@filepath+@table+'\'+@table+@createDate+'-'+@business_end+'.csv';

exec  report_data.[dbo].est_export_cvs @table,@Server,@Expoprtfilename;	
------------discount------------------------
---R1_3
if OBJECT_ID('tempdb..#ftprd1') is not null 
  drop  table #ftprd1

 delete report_data.[dbo].[R1_3_tran_discount] ;
 set @sql_text_org=N'
 
 select  distinct  TicketInternalKey, ftprd1.PromotionId ,    ftprd1.RewardValue   as RewardValue , entityid  into #ftprd1 
  from  [ATD_Shell].dbo.FO_TranPromotionRewardApportionment201704 ftprd1 where RewardMethodId=4  
 create index fptr on #ftprd1(ticketInternalkey)
 insert into  report_data.[dbo].[R1_3_tran_discount] (
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
		    ,upc                      --16.1
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
 , item.sku                           --16SKU
 ,   ftprd.EntityId                   --upc            
 
  ,  item.FullName                        --17商品
	--,fts.Price,                               --18
	--,fth.thbz*fts.Qty as qty ,                                  --18数量
	--fth.thbz*fts.Amount as amount ,                           --19应收金额
    , isnull(ftprd.rewardValue,0)  rewardValue              --20优惠金额
	 --,fth.thbz*fts.amount-isnull(ftprd.rewardValue,0) as netamount  --21实付金额
	-- ,fth.thbz*ftprd1.RewardValue as RewardvaluePoint        --22获得积分
	--, fth.thbz*ftprd1.RewardValue/6   as reward_amount                            --23积分发放金额
	 ,ftprd.PromotionId                                            --24促销id
	 ,phpr.ExternalGroupId --phpr.PromotionGroupId                                 --25促销组
	 ,substring(phpr.ExternalReferenceID,1,8)                             --26 外部促销id
	 ,convert(varchar,fth.CreatedDate,120)                  --27 上传日期
	--  ,ftprd1.PromotionId as pointPromotionId        --获得积分促销id
 from 
		  [ATD_Shell].dbo.FO_TranHeader201704 fth
	 
		
		  
		  inner  join [ATD_Shell].[dbo].[FO_TranCollection] ftc
		 
on ftc.CollectionInternalKey=fth.CollectionInternalKey
 inner  join  [report_data].[dbo].store_gs store on store.storeid=ftc.storeid and store.MatrixMemberId=@MatrixMemberId
   left join  Loyalty_Shell_1. [dbo].[CRM_POSTran] cp 
    on cp.TranId=fth.TranId and cp.PosDateTime=ftc.BusinessDate and cp.StoreInternalKey=store.StoreInternalKey
	and  cp.MatrixMemberId=@MatrixMemberId
--	inner join [ATD_Shell].dbo.FO_TranSale201704 fts
--	on fts.TicketInternalKey=fth.TicketInternalKey
		left join #ftprd1  ftprd
	on ftprd.TicketInternalKey=fth.TicketInternalKey   --and ftprd.EntityId=fts.ItemId 
  -- left join (select  distinct  TicketInternalKey, ftprd1.PromotionId ,ftprd1.RewardValue , entityid 
--  from  [ATD_Shell].dbo.FO_TranPromotionRewardApportionment201704 ftprd1 where RewardMethodId=1) ftprd1
 -- on ftprd1.TicketInternalKey=fts.TicketInternalKey  --and ftprd1.EntityId=fts.ItemId 
   inner join report_data.[dbo].[PromotionHeader_PR] phpr 
	on phpr.PromotionHeaderId=ftprd.PromotionId  and  phpr.MatrixMemberId=@MatrixMemberId
	left join  [report_data].[dbo].item_cat  item 
	on item.MainItemId=ftprd.EntityId and item.MatrixMemberId=@MatrixMemberId
	 left join    [Loyalty_Shell_1].[dbo].[CRM_Member] cm  on cp.BuyingUnitInternalKey=cm.BuyingUnitInternalKey
	
	    left join   report_data.[dbo].[v_get_reg_compAndStore]   s   on s.BuyingUnitInternalKey=cm.BuyingUnitInternalKey 
		and s.MatrixMemberId=@MatrixMemberId--首次注册油站


  where  fth.CreatedDate>=convert(date,@createDate,120)   and  fth.CreatedDate<convert(date,@createdDateNextday,120) ';
	set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_pre);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
	set @sql_text = replace(@sql_text,'@createDate',''''+@createDate+'''');
 	set @sql_text = replace(@sql_text,'@createdDateNextday',''''+@createdDateNextday+'''');
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
	set @sql_text = replace(@sql_text,'@businessDate',''''+@businessDate+'''');
	exec(@sql_text);
	if OBJECT_ID('tempdb..#ftprd1') is not null 
  drop  table #ftprd1
	set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_cur);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
		set @sql_text = replace(@sql_text,'@createDate',''''+@createDate+'''');
 	set @sql_text = replace(@sql_text,'@createdDateNextday',''''+@createdDateNextday+'''');
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
	set @sql_text = replace(@sql_text,'@businessDate',''''+@businessDate+'''');
	SELECT @sql_text;
	exec(@sql_text);
	 
	set  @table='R1_3_tran_discount';
    print @table
	set  @Expoprtfilename=@filepath+@table+'\'+@table+@createDate+'-'+@business_end+'.csv';

exec  report_data.[dbo].est_export_cvs @table,@Server,@Expoprtfilename;	


---------R1_3





if OBJECT_ID('tempdb..#ftprd1') is not null 
  drop  table #ftprd1
----------------reward point---------------------
delete report_data.[dbo].[r1_2_tran_reward] ;
set @sql_text_org=N'

select  distinct  TicketInternalKey, ftprd1.PromotionId ,ftprd1.RewardValue , entityid  into #ftprd1
  from  [ATD_Shell].dbo.FO_TranPromotionRewardApportionment201704 ftprd1 where   RewardMethodId=1 and RewardId=100
  create index fptr on #ftprd1(ticketInternalkey)

insert into  report_data.[dbo].[r1_2_tran_reward] (
            [member_card_no]              --1
           , member_reg_comp_code          --2.0
           , member_reg_comp				  --2
           , member_reg_store_code         --3.0
           , member_reg_store              --3
		   
           , legal_code                    --6
           , legal_name                    --6.1
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
   
 ,   ftprd1.EntityId                              --16SKU
  ,  item.FullName                        --17商品
	
	 ,ftprd1.RewardValue as RewardvaluePoint        --22获得积分
	, round(ftprd1.RewardValue/@bal,2)   as reward_amount                            --23积分发放金额
	 ,ftprd1.PromotionId                                            --24促销id
	 ,phpr.ExternalGroupId                                 --25促销组
	 
	 ,substring(phpr.ExternalReferenceID,1,8)                             --26 外部促销id
	 ,convert(varchar,fth.CreatedDate,120)                  --27 上传日期

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
		
   left join #ftprd1 ftprd1
  on ftprd1.TicketInternalKey=fth.TicketInternalKey   --and ftprd1.EntityId=fts.ItemId 
    left join report_data.[dbo].[PromotionHeader_PR] phpr 
	on phpr.PromotionHeaderId=ftprd1.PromotionId and phpr.MatrixMemberId=@MatrixMemberId
	left join  [report_data].[dbo].item_cat  item    on item.MainItemId=ftprd1.EntityId   and item.MatrixMemberId=@MatrixMemberId
	left join    [Loyalty_Shell_1].[dbo].[CRM_Member] cm  on cp.BuyingUnitInternalKey=cm.BuyingUnitInternalKey
	/* left join   report_data.dbo.CRM_MemberStoreAssign_shell cmsa 
	    on cm.MemberInternalKey=cmsa.MemberInternalKey and cmsa.StoreTypeId=2 and cmsa.MatrixMemberId=@MatrixMemberId
	left join 	[report_data].[dbo].store_gs    s on s.StoreInternalKey=cmsa.StoreInternalKey
        and  s.MatrixMemberId=@MatrixMemberId  */
		 left join   report_data.[dbo].[v_get_reg_compAndStore]   s   on s.BuyingUnitInternalKey=cm.BuyingUnitInternalKey --首次注册油站
and s.MatrixMemberId=@MatrixMemberId
  where fth.CreatedDate>=convert(date,@createDate,120)   and  fth.CreatedDate<convert(date,@createdDateNextday,120) 
  and phpr.PromotionHeaderId is not null ';
	set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_pre);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
	set @sql_text = replace(@sql_text,'@createDate',''''+@createDate+'''');
 	set @sql_text = replace(@sql_text,'@createdDateNextday',''''+@createdDateNextday+'''');
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
		set @sql_text = replace(@sql_text,'@businessDate',''''+@businessDate+'''');
	print @sql_text;
	exec(@sql_text);
	if OBJECT_ID('tempdb..#ftprd1') is not null 
  drop  table #ftprd1
	set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_cur);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
	set @sql_text = replace(@sql_text,'@createDate',''''+@createDate+'''');
 	set @sql_text = replace(@sql_text,'@createdDateNextday',''''+@createdDateNextday+'''');
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
	set @sql_text = replace(@sql_text,'@businessDate',''''+@businessDate+'''');
	exec(@sql_text);
	
	set  @table='R1_2_tran_reward';
   set  @Expoprtfilename=@filepath+@table+'\'+@table+@createDate+'-'+@business_end+'.csv';
	print @table
    exec  report_data.[dbo].est_export_cvs @table,@Server,@Expoprtfilename;	
------------------------------------
 --R2-油站积分兑换 
 -- set @redemption_point_sql=
 delete  report_data. [dbo].R2_redemption_point;
set  @sql_text_org=N'insert into report_data. [dbo].R2_redemption_point
          ([member_card_no]                   --1
          , member_reg_comp_code              --2
          ,  member_reg_comp				  --3
          ,  member_reg_store_code            --4
          ,  member_reg_store			      --5
          ,  legal_code                       --6
          ,  legal_name                       --7
          ,  store_code                       --8 
          ,  store_name                       --9
           ,[city]                           --10
           ,[cashier_id]                     --11
           ,[transaction_no]                 --12
           ,[business_date]                  --13
           ,[transaction_date]               --14
           ,[transaction_time]               --15
           ,[posid]                          --16
           ,[item_cat]                       --17
           ,[item_cat_mid]                   --18
            ,item_cat_mid_name               --19
           ,[item]                           --20
		   ,[item_name]                      --21
           ,[quantity]                       --22
           ,[redemption_point_q]             --23
		    , redemption_point_je            --24  积分折算金额

           ,[redemption_point_amount]       --25
		   ,redem_ce                        --26差额  
           ,[promotion_id]                  --27
           ,[promotion_group]               --28
		    ,promtion_ref                   --29
		   ,create_date                     --30
		   )
select   cp.ClubCardId,                                  --1会员号码

 s.compid    compid                                      --2.0
,s.comp      regcomp                                     --3会员注册公司
,s.storeid   storeid                                     --4.0会员注册油站     
,s.storename  regstore                                   --5会员注册默认油站
,store.comp as sal_com                                   --6公司代码
,store.compid as sal_com_id                             --7公司代码
  ,store.storeid                                         --8 油站代码
 ,store.storename as stor                                -- 9油站名称
 ,  store.city   as city,                                --10城市
    ftc.CashierId ,                                      --11cashierid
	  fth.TranId  ,                                      --12交易流水号
  convert(varchar(10), ftc.BusinessDate,120) businessDate,        --13营业日
   convert(varchar(10),ftc.createddate,120) trandate,             --14交易日期
   convert(varchar(8),ftc.createddate,8)  trantime,               --15交易时间
   ftc.TillId   posid   ,                                         --16 '
 set @sql_text_org=@sql_text_org+N' 
   item.firsttype,                               --17商品类型
  item.midtypeCode,                                               --18 商品中类
 item.midtype,                                                    --19 商品中类
 item.mainitemid,                                                 --20
  item.FullName,							                     -- 21 商品  
 ftprd.RewardedQty,                                               --22数量
case when ftprds.RewardValue=0 then ftpma.AdjustmentValue else 
    cast(ftprd.rewardValue/ftprds.RewardValue*ftpma.AdjustmentValue as  decimal(10,2))  end    Redemption_quantity,   --23                --19积分兑换数量 
      case when ftprds.RewardValue=0 then ftpma.AdjustmentValue/@bal else 
	     cast(  ftprd.rewardValue/ftprds.RewardValue*ftpma.AdjustmentValue/@bal  as   decimal(10,2)) end  as redemption_point_je , --24  积分折算金额
 cast( ftprd.rewardValue as  decimal(10,2))  redemption ,             --25积分抵扣金额 
-1*case  when  ftprds.RewardValue=0 then  -1*ftpma.AdjustmentValue/@bal else 
   cast(ftprd.rewardValue-ftprd.rewardValue/ftprds.RewardValue*ftpma.AdjustmentValue /@bal  as   decimal(10,2))
   end   as    redem_ce ,  -- 26差额'
    set @sql_text_org=@sql_text_org+N' 
  	 ftprd.PromotionId,                                  --27
	left( phpr.ExternalGroupId,5)                             --28

	 ,substring(phpr.ExternalReferenceID,1,8)                          --29 外部促销id
	 ,convert(varchar,cp.CreatedAt,120)                 --30 上传日期;


 
     from  Loyalty_Shell_1. [dbo].[CRM_POSTran] cp
    inner join   [report_data].[dbo].store_gs  store1 on store1.StoreInternalKey=cp.StoreInternalKey  and cp.MatrixMemberId=@MatrixMemberId
    and store1.MatrixMemberId=@MatrixMemberId   
	 inner  join [ATD_Shell].[dbo].[FO_TranCollection] ftc  on ftc.BusinessDate=cp.PosDateTime  and store1.storeid=ftc.StoreId
 	  inner join	   [ATD_Shell].dbo.FO_TranHeader201704    fth
    on fth.CollectionInternalKey=ftc.CollectionInternalKey  and fth.TranId=cp.TranId  
inner join (
    select   ftprd1.TicketInternalKey, ftprd1.PromotionId ,sum(ftprd1.RewardValue) RewardValue  
    from  [ATD_Shell].[dbo].[FO_TranPromotionRewardApportionment201704] ftprd1  
	   where RewardMethodId in (5,3) 
	   group by ftprd1.TicketInternalKey, ftprd1.PromotionId  /* having sum(ftprd1.RewardValue)<>0 */) ftprds
	   on ftprds.TicketInternalKey=fth.TicketInternalKey
	inner join      [ATD_Shell].[dbo].[FO_TranPromotionRewardApportionment201704] ftprd  
	-- on ftprd.TicketInternalKey=fth.TicketInternalKey  
	 on  ftprds.TicketInternalKey=ftprd.TicketInternalKey and ftprd.PromotionId=ftprds.PromotionId
	  and ftprd.RewardMethodId in (5,3) 

	inner join   [ATD_Shell].[dbo].[FO_TranPromotionMemberAccount201704] ftpma 
	on ftprds.TicketInternalKey=ftpma.TicketInternalKey and ftpma.PromotionId=ftprds.PromotionId'
  
  set @sql_text_org=@sql_text_org+N'  left join  report_data.[dbo].[PromotionHeader_PR] phpr 	on phpr.PromotionHeaderId=ftprd.PromotionId  and phpr.MatrixMemberId=@MatrixMemberId
	left join  [report_data].[dbo].item_cat  item 	on item.MainItemId=ftprd.EntityId  and item.MatrixMemberId=@MatrixMemberId  
	 left join    [Loyalty_Shell_1].[dbo].[CRM_Member] cm  on cp.BuyingUnitInternalKey=cm.BuyingUnitInternalKey
   left join   report_data.[dbo].[v_get_reg_compAndStore]   s   on s.BuyingUnitInternalKey=cm.BuyingUnitInternalKey --首次注册油站
 and s.MatrixMemberId=@MatrixMemberId  -- and cp.MatrixMemberId=store.MatrixMemberId
 left join [report_data].[dbo].store_gs  store on cp.StoreInternalKey=store.StoreInternalKey and store.MatrixMemberId=@MatrixMemberId
    where      fth.CreatedDate>=convert(date,@createDate,120)   and  fth.CreatedDate<convert(date,@createdDateNextday,120) 
  and cp.MatrixMemberId=@MatrixMemberId    
   '

  set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_pre);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);


	set @sql_text = replace(@sql_text,'@createDate',''''+@createDate+'''');
 	set @sql_text = replace(@sql_text,'@createdDateNextday',''''+@createdDateNextday+'''');
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);

	print @sql_text
	exec(@sql_text);
	set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_cur);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);

	set @sql_text = replace(@sql_text,'@createDate',''''+@createDate+'''');
 	set @sql_text = replace(@sql_text,'@createdDateNextday',''''+@createdDateNextday+'''');
set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);

	exec(@sql_text);
   set  @table='R2_redemption_point'
  set  @Expoprtfilename=@filepath+@table+'\'+@table+@createDate+'-'+@business_end+'.csv';
   print @table
   exec  report_data.[dbo].est_export_cvs @table,@Server,@Expoprtfilename;	

  ---R7-支付方式
  set  @table='r7_payment_tender';
  --insert into payment_tender
 
 delete  report_data.[dbo].[r7_payment_tender]

 set @sql_text_org=N' INSERT INTO report_data.[dbo].[r7_payment_tender]
 ([member_card_no]
           ,[store_code]
           ,[store_name]
           ,[legal_code]
		   ,[legal_name]
           ,[city]
           ,[cashier_id]
           ,[transaction_no]
           ,[business_date]
           ,[pos_id]
           ,[tender]
           ,[amount]
		   ,create_date                
		   )

select 
   cp.ClubCardId                   --会员号码
   ,s.storeid                           --油站代码
      ,s.storename        --油站名称
	,s.compid as gs1                       --公司代码
	,s.comp
	, s.city                                --城市
	,ftc.CashierId                         --  Cashier ID
	,fth.TranId                            --交易流水号
	,  convert(varchar(10),ftc.BusinessDate ,120)                                       --营业日
	,ftc.TillId                            --POS ID
	,tender.TenderName        --支付方式
	,ttender.Amount               --金额,
	,convert(varchar,fth.CreatedDate,120) 
     from  [ATD_Shell].dbo.FO_TranHeader201704 fth 
		   inner join  [ATD_Shell].[dbo].[FO_TranCollection] ftc
on ftc.CollectionInternalKey=fth.CollectionInternalKey 
inner join [report_data].[dbo].store_gs  store1 on store1.Storeid=ftc.StoreId
left join Loyalty_Shell_1. [dbo].[CRM_POSTran] cp
    on cp.TranId=fth.TranId and ftc.BusinessDate=cp.PosDateTime 	and cp.StoreInternalKey=store1.StoreInternalKey and cp.PosId=ftc.TillId
   left join    [Loyalty_Shell_1].[dbo].[CRM_Member] cm  on cp.BuyingUnitInternalKey=cm.BuyingUnitInternalKey
     left join    [ATD_Shell].[dbo].[FO_TranTender201704]  ttender    on fth.TicketInternalKey=ttender.TicketInternalKey
  left join [ATD_Shell].[dbo].[Tender_ALL] tender on ttender.StoreTenderId=tender.TenderId and tender.MatrixMemberId=@MatrixMemberId
left join    report_data.dbo.CRM_MemberStoreAssign_shell cmsa 	    on cm.MemberInternalKey=cmsa.MemberInternalKey  and cmsa.StoreTypeId=2
     
left join 	[report_data].[dbo].store_gs    s on s.storeid=ftc.StoreId

 --left join   report_data.[dbo].[v_get_reg_compAndStore]   s   on s.BuyingUnitInternalKey=cm.BuyingUnitInternalKey --首次注册油站
and s.MatrixMemberId=@MatrixMemberId
where  fth.CreatedDate>=convert(date,@createDate,120)   and  fth.CreatedDate<convert(date,@createdDateNextday,120) 
  and ftc.RetailerId=@retailerId 
   and ftc.TranTypeId in (20,23)  
 '

 set @sql_text=@sql_text_org;

	set @sql_text = replace(@sql_text,'201704',@tableDate_pre);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
	set @sql_text = replace(@sql_text,'@createDate',''''+@createDate+'''');
 	set @sql_text = replace(@sql_text,'@createdDateNextday',''''+@createdDateNextday+'''');
	set @sql_text = replace(@sql_text,'@bal',@bal);
set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
		set @sql_text = replace(@sql_text,'@businessDate',''''+@businessDate+'''');
		set @sql_text = replace(@sql_text,'@retailerId',''''+@retailerId+'''');

	exec(@sql_text);
	set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_cur);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
	set @sql_text = replace(@sql_text,'@createDate',''''+@createDate+'''');
 	set @sql_text = replace(@sql_text,'@createdDateNextday',''''+@createdDateNextday+'''');
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
	set @sql_text = replace(@sql_text,'@businessDate',''''+@businessDate+'''');
		set @sql_text = replace(@sql_text,'@retailerId',''''+@retailerId+'''');
	exec(@sql_text);
	--	print @sql_text;
 set  @table='r7_payment_tender';
set  @Expoprtfilename=@filepath+@table+'\'+@table+@createDate+'-'+@business_end+'.csv';

exec  report_data.[dbo].est_export_cvs @table,@Server,@Expoprtfilename;	
print @table

 

--- R9-point detail list related to central adjustment 中央积分发放
--insert into adjust_center_point
delete report_data.[dbo].[r9_adjust]
set @sql_text_org=N'INSERT INTO report_data.[dbo].[r9_adjust]
           ([member_card_no]		--1
           ,[member_reg_comp]		--2
           ,[member_reg_store]		--3
           ,[store_id]				--4
           ,[transaction_no]		--5
           ,[business_date]			--6
           ,[pos_id]				--7
           ,[reason_adjust]			--8
           ,[number_awarding]		--9
           ,[number_redemption_amount] --10
           ,date_expired				--11
  --         ,[number_awarding_amount]
		   )   --12积分发行金额

select  cm.externalmemberkey     --1会员号码
,s.compid as regcomp                  --2会员注册公司
,s.storename regstore                       --3会员默认油站

,s.storeid                                   --4油站代码
,paa.PosTranInternalKey                  --5交易流水号
,convert(varchar(10),paa.PosDateTime,120)                           --6营业日
,cp.PosId                                         --7posid
 ,isnull(gd.Value,purc.ReasonDescription)               --8积分调整原因
 ,   paa.EarnValue-paa.RedeemValue  EarnValue  --9积分发行数量
 , 0 --redempton        ---10积分兑换数量
 ,convert(varchar(10),paa.ExpirationDate,120)                       --11积分过期日期
-- ,round(paa.EarnValue /@bal,2)  as awarding_amount      --12积分发行金额
     from      Loyalty_Shell_1. [dbo].CRM_POSAccountsActivity  paa
    left join Loyalty_Shell_1.[dbo].[CRM_PointsUpdateReasonCodes] purc on paa.ReasonCode=purc.ReasonCode
	left join MP_Shell.dbo.GeneralDictionary gd on gd.EntryId=purc.ReasonDescription and gd.LanguageId=8
 
		 left join    [Loyalty_Shell_1].[dbo].[CRM_Member] cm  on paa.BuyingUnitInternalKey=cm.BuyingUnitInternalKey
	/*  left join    report_data.dbo.CRM_MemberStoreAssign_shell cmsa 
	    on cm.MemberInternalKey=cmsa.MemberInternalKey and cmsa.StoreTypeId=2
		left join 	[report_data].[dbo].store_gs    s on s.StoreInternalKey=cmsa.StoreInternalKey */
		inner join   report_data.[dbo].[v_get_reg_compAndStore]   s   on s.BuyingUnitInternalKey=cm.BuyingUnitInternalKey --首次注册油站
		and s.MatrixMemberId=@MatrixMemberId
   left join [report_data].[dbo].store_gs  store on s.StoreInternalKey=store.StoreInternalKey and   store.MatrixMemberId=s.MatrixMemberId
   left join   Loyalty_Shell_1. [dbo].[CRM_POSTran] cp on cp.POSTranInternalKey=paa.PosTranInternalKey
 where
  (posid=-66 or  posid=-99)   -- and paa.ReasonCode<>7  ---注意erp 不包含B2C手动积分,R报表包含.
   and paa.AccountInternalKey=2034  
  and   cp.CreatedAt>=convert(date,@createDate,120)   and  cp.CreatedAt<convert(date,@createdDateNextday,120)   

  ';

 set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@TableDate_cur);
	set @sql_text = replace(@sql_text,'@createDate',''''+@createDate+'''');
 	set @sql_text = replace(@sql_text,'@createdDateNextday',''''+@createdDateNextday+'''');
 set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
	

	exec(@sql_text);
	
 set  @table='r9_adjust';
 print @table;
set  @Expoprtfilename=@filepath+@table+'\'+@table+@createDate+'-'+@business_end+'.csv';
exec  report_data.[dbo].est_export_cvs @table,@Server,@Expoprtfilename;	


  
 
--insert into .R10_1_member_list_top20
   delete report_data.dbo.R10_1_fraud_control;
set @sql_text_org=N'
INSERT INTO  report_data.[dbo].[R10_1_fraud_control]  
           ([row_num]             --1     排序号
           ,[tran_date]           --2     交易日期
           ,[store_id]            --3      店编号
           ,[store_name]          --4      店名
           ,[comp_name]          --5       公司名
           ,[comp_id]            --6       公司编号
           ,[member_card_no]          --7       会员卡号
           ,[petrol_amount]       --8      汽油积分
           ,[diesel_oil_amount]   --9      柴油积分
           ,[conven_goods_amount]  --10   便利店积分
           ,[total_amount])         --11  总积分
 SELECT * FROM (
 select   --ROW_NUMBER() over ( partition by  ftc.StoreId,store.storename,store.compID,store.comp order by sum(ftprd.RewardValue) desc )
 ROW_NUMBER() over ( partition by  ftc.StoreId,store.storename,store.compID,store.comp order by  sum( case when item.midtypeCode=1001 then 1  else 0 end )+sum( case when item.midtypeCode=1002 then 1 else 0 end ) 
+ sum(  distinct  case when item.midtypeCode not in (1002,1001)  then  1 else 0 end ) desc )
AS  Rownum                                 --1
 , convert(varchar(10),ftc.BusinessDate,120)  tran_date                      --2
 ,ftc.StoreId                              --3
 ,store.storename                          --4
 ,store.comp                               --5
 ,store.compID                               --6
 ,cm.ExternalMemberKey                    --7
 , sum( case when item.midtypeCode=1001 then 1  else 0 end ) aspetrol_amount   -- sum( case when item.midtypeCode=1001 then ftprd.RewardValue else 0 end ) aspetrol_amount  --8
 ,  sum( case when item.midtypeCode=1002 then 1 else 0 end ) as diesel_oil_amount   --sum( case when item.midtypeCode=1002 then ftprd.RewardValue else 0 end ) as diesel_oil_amount  --9
  ,sum(  distinct  case when item.midtypeCode not in (1002,1001)  then  1 else 0 end ) as conven_goods_amount     --sum( case when item.midtypeCode not in (1002,1001)  then ftprd.RewardValue else 0 end ) as conven_goods_amount --10
 ,   sum( case when item.midtypeCode=1001 then 1  else 0 end )+sum( case when item.midtypeCode=1002 then 1 else 0 end ) 
+ sum(  distinct  case when item.midtypeCode not in (1002,1001)  then  1 else 0 end )    as total_amount    --11
  from   [ATD_Shell].dbo.FO_TranPromotionRewardApportionment201704  ftprd 
   left join     [ATD_Shell].dbo.FO_TranHeader201704  fth on fth.TicketInternalKey=ftprd.TicketInternalKey
  inner  join    [ATD_Shell].[dbo].[FO_TranCollection] ftc on ftc.CollectionInternalKey=fth.CollectionInternalKey
   left join    loyalty_shell_1. [dbo].[CRM_POSTran] cp on cp.TranId=fth.TranId 
    and cp.PosDateTime=ftc.BusinessDate
	inner join    [report_data].[dbo].item_cat  item  	on item.MainItemId=ftprd.EntityId 
	inner join [report_data].[dbo].store_gs  store on cp.StoreInternalKey=store.StoreInternalKey  and ftc.StoreId=store.storeid
	and store.MatrixMemberId=cp.MatrixMemberId
	inner  join    [Loyalty_Shell_1].[dbo].[CRM_Member] cm  on cp.BuyingUnitInternalKey=cm.BuyingUnitInternalKey
 where ftprd.RewardMethodId=1 
 and  fth.CreatedDate>=convert(date,@createDate,120)   and  fth.CreatedDate<convert(date,@createdDateNextday,120) 
and ftc.RetailerId=@RetailerId 
 group by  ftc.BusinessDate,ftc.StoreId,store.storename,store.compID,store.comp,cm.ExternalMemberKey)a 
 where rownum<=20
  '
     set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@TableDate_cur);
	set @sql_text = replace(@sql_text,'@createDate',''''+@createDate+'''');
 	set @sql_text = replace(@sql_text,'@createdDateNextday',''''+@createdDateNextday+'''');

 set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
	set @sql_text = replace(@sql_text,'@bal',@bal);
			set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);

	set @sql_text = replace(@sql_text,'@retailerId',''''+@retailerId+'''');
	print @sql_text;
	exec(@sql_text);
	
   set  @table='R10_1_fraud_control';
   print @table
set  @Expoprtfilename=@filepath+@table+'\'+@table+@createDate+'-'+@business_end+'.csv';
exec  report_data.[dbo].est_export_cvs @table,@Server,@Expoprtfilename;	

---------每周各站会员积分前5名------------------
 	if OBJECT_ID('tempdb..##cpt') is not null
        drop table ##cpt

  delete report_data.dbo.R10_2_top5_detail;
set @sql_text_org=N'
 
 select  *  into ##cpt from Loyalty_Shell_1..CRM_POSTran cpt
	 where cpt.PosDateTime>convert(datetime ,@businessDate,120)-7 and cpt.PosDateTime<=convert(datetime,@businessDate,120) and IsTransactionVoid  =0 and MatrixMemberId=@MatrixMemberId  
create index  cptposintelkey  on ##cpt(PosTranInternalKey)
create index cptbuy on ##cpt(BuyingUnitInternalKey,MatrixMemberId)
 insert   R10_2_top5_detail (
	[OrderNumber],   --1
	[TranDate],      --2
	[TranTime],     --3
	[Amount] ,      --4
	[StoreId] ,    --5
	[StoreName],  --6
	[CompID],       --7
	[CompName] ,    --8
	[member_card_no] ,        --9
	[MobilePhone],     --  10
	point   ----11
		)
   select 
   
    sequence                          --1
 , convert(varchar(10),cpt.PosDateTime,120)  tran_date                      --2
 ,convert(varchar(8),cpt.CreatedAt ,114) time            --3
  ,cpt.SalesAmount      --4
 ,store.StoreId                              --5
 ,store.storename                          --6
 ,store.compID                               --7
 ,store.comp                               --8
 ,cm.ExternalMemberKey                    --9
  ,cm.MobilePhoneNumber            --10
 ,cpaa.EarnValue                   --11
    
    from (select * from ( select  ROW_NUMBER() over( partition by cpt.StoreInternalKey order by  sum(earnValue) desc   ) sequence,  sum(earnValue) as points,cpt.StoreInternalKey ,cpt.BuyingUnitInternalKey,cpt.MatrixMemberId
    from  Loyalty_Shell_1..CRM_POSAccountsActivity cpaa
  inner join ##cpt  cpt on cpaa.PosTranInternalKey=cpt.POSTranInternalKey   and AccountInternalKey=2034  and cpaa.MatrixMemberId=cpt.MatrixMemberId
       group by cpt.StoreInternalKey , cpt.BuyingUnitInternalKey,cpt.MatrixMemberId  )  buyingUnit  where sequence<=5) buyingunit 
   
    inner join ##cpt cpt on buyingUnit.BuyingUnitInternalKey=cpt.BuyingUnitInternalKey and cpt.MatrixMemberId=buyingUnit.MatrixMemberId
	 inner join  Loyalty_Shell_1..CRM_POSAccountsActivity cpaa on  cpaa.PosTranInternalKey=cpt.POSTranInternalKey   and AccountInternalKey=2034  
	      and cpaa.MatrixMemberId=cpt.MatrixMemberId
inner join [report_data].[dbo].store_gs  store on cpt.StoreInternalKey=store.StoreInternalKey and store.MatrixMemberId=cpt.MatrixMemberId
inner  join    [Loyalty_Shell_1].[dbo].[CRM_Member] cm  on cpt.BuyingUnitInternalKey=cm.BuyingUnitInternalKey   order by store.StoreId ,sequence 
   
 
    '
;

 set @sql_text=@sql_text_org;
	
declare  @R10businessDate varchar(10)
set @R10businessDate=convert(varchar(10),convert(datetime,@businessDate,120)+1,120);
 set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
set @sql_text = replace(@sql_text,'@businessDate',''''+@R10businessDate+'''');
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
   print @sql_text
declare @weekday0 int;
select  @weekday0=DATEPART(weekday,@R10businessDate)
	if @weekday0=1
	 begin exec(@sql_text);
	
   set  @table='R10_2_top5_detail';
   print @table
   set  @Expoprtfilename=@filepath+@table+'\'+@table+@R10businessDate+'.csv';
    exec  report_data.[dbo].est_export_cvs @table,@Server,@Expoprtfilename;	
  end;


----------------------2018-09-18  每周积分获得次数>10次抓取的模板---
  delete report_data.dbo.R10_3_top10_TranFreq;
set @sql_text_org=N'
   
 insert [R10_3_top10_TranFreq] (
	[OrderNumber],   --1
	[TranDate],      --2
	[TranTime],     --3
	[Amount] ,      --4
	[StoreId] ,    --5
	[StoreName],  --6
	[CompID],       --7
	[CompName] ,    --8
	[member_card_no] ,        --9
	[MobilePhone]     --  10
		)

     select 
         sequence  ,                    --1
 convert(varchar(10),cpt.PosDateTime,120)  tran_date                      --2
 ,convert(varchar(8),cpt.CreatedAt ,114)   time   --3
  ,cpt.SalesAmount   --4
 ,store.StoreId                              --5
 ,store.storename                          --6
  ,store.compID                               --7
  ,store.comp                               --8
 ,cm.ExternalMemberKey                    --9
  ,cm.MobilePhoneNumber
  from   (select  ROW_NUMBER() over( order by  count(1) desc   ) sequence,  count(*) as times ,cpt.BuyingUnitInternalKey,cpt.MatrixMemberId
    from  Loyalty_Shell_1..CRM_POSAccountsActivity cpaa
  inner join ##cpt  cpt on cpaa.PosTranInternalKey=cpt.POSTranInternalKey   and AccountInternalKey=2034  and cpaa.MatrixMemberId=cpt.MatrixMemberId
       group by  cpt.BuyingUnitInternalKey,cpt.MatrixMemberId  having count(1)>10)  buyingUnit
	 inner join ##cpt cpt on buyingUnit.BuyingUnitInternalKey=cpt.BuyingUnitInternalKey and cpt.MatrixMemberId=buyingUnit.MatrixMemberId
	 inner join  Loyalty_Shell_1..CRM_POSAccountsActivity cpaa on  cpaa.PosTranInternalKey=cpt.POSTranInternalKey   and AccountInternalKey=2034  
	      and cpaa.MatrixMemberId=cpt.MatrixMemberId
inner join [report_data].[dbo].store_gs  store on cpt.StoreInternalKey=store.StoreInternalKey and store.MatrixMemberId=cpt.MatrixMemberId
inner  join    [Loyalty_Shell_1].[dbo].[CRM_Member] cm  on cpt.BuyingUnitInternalKey=cm.BuyingUnitInternalKey  order by 1  '

    set @sql_text=@sql_text_org;
	

 set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
	set @sql_text = replace(@sql_text,'@businessDate',''''+@R10businessDate+'''');
   print @sql_text
   
	if @weekday0=1
	 begin exec(@sql_text);
	
   set  @table='R10_3_top10_TranFreq';
   print @table
   set  @Expoprtfilename=@filepath+@table+'\'+@table+@R10businessDate+'.csv';
    exec  report_data.[dbo].est_export_cvs @table,@Server,@Expoprtfilename;	
  end;----------------



--R13-promotion listR13-promotion list 
delete report_data.[dbo].[R13_promotion_list];
 set   @sql_text_org=N'INSERT INTO report_data.[dbo].[R13_promotion_list]
           ([promotion_id]					 --1
           ,[promotion_group_id]            --2
		   ,promotion_group_desc			--3
           ,[promotion_desc]				--4
           ,[promotion_start_date]			--5
           ,[promotion_end_date]			--6
		   ,state                          --7
		    ,[promotion_code]            --2
		   ,update_date                   --9
		   )
  select  distinct substring(phpr.ExternalReferenceID,1,8)       ---1外部促销ID
,phpr.ExternalGroupId   --   20170809             --2促销组ID
, PromotionGroupName   --3
,PromotionHeaderDescription      --4促销描述 
,	phpr.PromotionHeaderStartDate --5促销开始日期
,phpr.PromotionHeaderEndDate        --6促销结束日期
,case when phpr.SuspendStatus=1 then N'''+N'正常'+'''
ELSE N'''+N'挂起'+''' end  status ,
phpr.PromotionHeaderId,
UpdatedDate                         --更新日期 
   from    [ATD_Shell].dbo.FO_TranHeader201704  fth  
		 inner  join [ATD_Shell].[dbo].[FO_TranCollection] ftc
on ftc.CollectionInternalKey=fth.CollectionInternalKey
 inner  join  [report_data].[dbo].store_gs store on store.storeid=ftc.storeid
  left join   
   [ATD_Shell].dbo.FO_TranPromotionRewardApportionment201704 ftprd1   
  on ftprd1.TicketInternalKey=fth.TicketInternalKey  and  RewardMethodId in (1,4,5)    
   inner join [report_data].[dbo].[PromotionHeader_PR] phpr 
	on phpr.PromotionHeaderId=ftprd1.PromotionId	and phpr.MatrixMemberId=@MatrixMemberId
   where   fth.CreatedDate>=convert(date,@createDate,120)   and  fth.CreatedDate<convert(date,@createdDateNextday,120) 
   ';
  set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@TableDate_cur);
		set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
	set @sql_text = replace(@sql_text,'@createDate',''''+@createDate+'''');

 	set @sql_text = replace(@sql_text,'@createdDateNextday',''''+@createdDateNextday+'''');

	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
	
	exec(@sql_text);
	
   set  @table='R13_promotion_list';
   print  @table;
set  @Expoprtfilename=@filepath+@table+'\'+@table+@createDate+'-'+@business_end+'.csv';
exec  report_data.[dbo].est_export_cvs @table,@Server,@Expoprtfilename;	



--  ----R_HK001_Invoice  start-----

declare  @MSequence int='1000'
insert R_HK001_Invoice_Version(StartRunTime) values(getdate())
select @MSequence=max(version) from R_HK001_Invoice_Version
 
if OBJECT_ID('tempdb..#ftprd1') is not null 
  drop  table #ftprd1

  delete report_data.[dbo].[R_HK001_Invoice] ;
 set @sql_text_org=N'
 
 select  distinct  TicketInternalKey, ftprd1.PromotionId ,    ftprd1.RewardValue   as RewardValue , entityid into  #ftprd1 
  from  [ATD_Shell].dbo.FO_TranPromotionRewardApportionment201704 ftprd1 where RewardMethodId=4 
 insert into  report_data.[dbo].[R_HK001_Invoice] (
              Identifier             --1
			, Site_id               --2.0
            ,OperatorId			    --3
          , TransDate               --4
          ,  ProductId              --5
		  
          ,  DisCount                    --6
          ,  Currency                    --7
           ,VATCode						--8
           ,Headtext					--9
           ,Itemtext			--10
           ,version
		   )
select '''+'002'+'''         --1默认固定值002
, store.storeid                 --2 
, '''+'000'+'''          --3门店所有者ID
,convert(varchar(8),fth.StartDateTime,112)  trandate                   --4交易日期     

 ,item.midtypeCode                                  --5商品中类
     , str(isnull(ftprd.rewardValue,0),13,2)  rewardValue              --6优惠金额
,'''+'HKD'+''' as Currency   --7
,0   as VatCode          --8
,'''+'SCMS_HK_'''+'+'+'convert(varchar(4),fth.StartDateTime,112)+@MSequence   as  headtext  --9
,'''+'Invoice Item Details'+   '''   --10
,@msequence	
 from 
		  [ATD_Shell].dbo.FO_TranHeader201704 fth
	 
		
		  
		  inner  join [ATD_Shell].[dbo].[FO_TranCollection] ftc
		 
on ftc.CollectionInternalKey=fth.CollectionInternalKey
 inner  join  [report_data].[dbo].store_gs store on store.storeid=ftc.storeid and store.MatrixMemberId=@MatrixMemberId
   left join #ftprd1 ftprd
	on ftprd.TicketInternalKey=fth.TicketInternalKey   --and ftprd.EntityId=fts.ItemId 
   	left join  [report_data].[dbo].item_cat  item 
	on item.MainItemId=ftprd.EntityId and item.MatrixMemberId=@MatrixMemberId
	

  where  fth.CreatedDate>=convert(date,@createDate,120)   and  fth.CreatedDate<convert(date,@createdDateNextday,120) 
	 and ftc.RetailerId=@Retailerid';
	set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_pre);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);

	
	 set @sql_text = replace(@sql_text,'@RetailerId',''''+@RetailerId+'''');
	 set @sql_text = replace(@sql_text,'@MSequence',''''+convert(varchar(10),@MSequence)+'''');
     set @sql_text = replace(@sql_text,'@createDate',''''+@createDate+'''');
    	set @sql_text = replace(@sql_text,'@createdDateNextday',''''+@createdDateNextday+'''');

	
	 
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
	select @sql_text;
	exec(@sql_text);

	set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_cur);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
		 set @sql_text = replace(@sql_text,'@RetailerId',''''+@RetailerId+'''');
	 set @sql_text = replace(@sql_text,'@MSequence',''''+convert(varchar(10),@MSequence)+'''');

	set @sql_text = replace(@sql_text,'@createDate',''''+@createDate+'''');
 	set @sql_text = replace(@sql_text,'@createdDateNextday',''''+@createdDateNextday+'''');
 
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
	select @sql_text
	exec(@sql_text);


	update R_HK001_Invoice  set OutputText=Identifier+Site_Id+OperatorID+TransDate+ProductId+Discount+Currency+VATCode+Headtext
	+Itemtext

-- 	declare @MSequence int =5
	delete  R_HK001_Invoce_head
  insert into R_HK001_Invoce_head(Identifier,FileType,CreateDate,CreateTime,Sequence,Productid)
  select distinct  '001' as identifier,'HK'+'02R005'+rtrim(ProductId) ,convert(varchar(8),getdate(),112)
   ,replace(convert(varchar(8),getdate(),8),':',''),@MSequence,ProductId  from  R_HK001_Invoice
   group by ProductId;

   insert into R_HK001_Invoice(Identifier,ProductId, OutputText)
     select Identifier,productid,  +'001'+FileType+CreateDate+CreateTime+Sequence  from R_HK001_Invoce_head
   

   insert into R_HK001_Invoice(Identifier,ProductId, OutputText) 
    select distinct  '003' as identifier,ProductId,'003'+ProductId+str(count(1),10)+str(sum(convert(float,r.Discount)),13,2) 
	from  R_HK001_Invoice r where r.Identifier='002'
   group by ProductId;

  declare  @filename varchar(50),@productid varchar(30),@version int
  declare  R_hk001_productid cursor
  for 
   select FileType,productid ,sequence   from   R_HK001_Invoce_head
  open   r_hk001_productid

  fetch next  from  r_hk001_productid into @filename,@productid,@version
  while @@fetch_STATUS = 0   
	begin
	  set  @table=rtrim(@filename)+rtrim(ltrim(str(@version)));
	  print @table;
   set  @Expoprtfilename=@filepath+'R_HK001_Invoice'+'\'+@table+'.txt';
 -- exec  report_data.[dbo].est_export_cvs @table,@Server,@Expoprtfilename;	
  select OutputText  from R_HK001_Invoice R where R.ProductId=@productid order by r.Identifier

  	declare @cmd varchar(1000) = 'bcp "select OutputText  from R_HK001_Invoice R where R.ProductId='''+@productid +'''order by r.Identifier"  queryout "'+@Expoprtfilename+ '"   -c -C65001   -T '
	print @cmd
	exec sys.xp_cmdshell @cmd


  fetch next  from  r_hk001_productid into @filename,@productid,@version

	end
close r_hk001_productid              
	deallocate r_hk001_productid


update R_HK001_Invoice_Version set FinishTime=getdate()  where Version=@MSequence
----R_HK001_Invoice end-----



   end;


GO
