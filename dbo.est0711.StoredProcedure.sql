USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[est0711]    Script Date: 1/19/2022 9:01:17 AM ******/
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
CREATE PROCEDURE [dbo].[est0711]
	 @createDate_begin varchar(10)='2017-03-01'   --yyyy-mm-dd
	,@createDate_end1 varchar(10)='2017-03-02' 
	
	AS
BEGIN
      declare  @createDate_end varchar(max)
	   set @createDate_end=@createDate_end1;
	 
	   set @createDate_end1=dateadd(day,-1,convert(date,@createDate_end1));
	    declare  @business_end   varchar(10);
		set @business_end=dateadd(day,-1,convert(date,@createDate_end1));
	    declare   @table VARCHAR(max) ='promotion_list'
		  ,@Server VARCHAR(max)   ='Loyalty_Shell_1.dbo.'
		  ,@FilePath NVARCHAR(100)=  'M:\upload\'  
		  ,@Expoprtfilename nvarchar(200)
		  ,@bal int =20; --per 6  point  for 1 rmb
    declare @tableDate_cur varchar(6) ,@tableDate_pre varchar(6) 
	,@atd_Server nvarchar(max) ='ATD_Shell'		
	,@ServerHost nvarchar(max)='HOST_Shell_1'
	,@loyalty_server varchar(max)='Loyalty_Shell_prod'
	,@sql_text  nvarchar(max)
	,@sql_text_org nvarchar(max)
	, @MatrixMemberId int=1
	 
	set @TableDate_cur=SUBSTRING(REPLACE(@createDate_begin,'-',''),1,6) --设置年月
	set @TableDate_pre=SUBSTRING(REPLACE(convert( varchar,dateadd(month,-1,@createDate_begin),120),'-',''),1,6) --设置年月 数据前一个月

	--declare  @fo_tranHeader varchar(max)=@atd_Server +'FO_TranHeader'+@tableDate  
	--              ,@FO_TranSale varchar(max)=@atd_Server +'FO_TranSale'+@tableDate
	--			  ,@FO_TranPromotionRewardApportionment varchar(max)=@atd_Server+'FO_TranPromotionRewardApportionment'+@tableDate
	print  @createDate_begin
	print @createDate_end
	
	

	
	
	
			      
--R1-交易明细表 -- 油站积分发放：可以到单个商品
-- insert tran_detail_reward_point
 
delete report_data.[dbo].[R1_tran] ;
 set @sql_text_org=N' insert into  report_data.[dbo].[R1_tran] (
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
,convert(varchar(10),cmsa.UpdatedDate,120)  --3.1注册时间
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
	   and cp.MatrixMemberId=@MatrixMemberId
	inner join  ( select  fts1.TicketInternalKey,fts1.ItemId,sum(fts1.Amount) as  amount,sum(fts1.qty) as qty  from  
	  [ATD_Shell].dbo.FO_TranSale201704 fts1   group  by  fts1.TicketInternalKey,fts1.ItemId ) fts
	on fts.TicketInternalKey=fth.TicketInternalKey
		left join (select    TicketInternalKey,		    sum(ftprd1.RewardValue)    as RewardValue , entityid
		 
  from  [ATD_Shell].dbo.FO_TranPromotionRewardApportionment201704 ftprd1 where RewardMethodId=4 
     group by  TicketInternalKey,entityid ) ftprd

	on ftprd.TicketInternalKey=fts.TicketInternalKey and ftprd.EntityId=fts.ItemId 
 	left join  [report_data].[dbo].item_cat  item 
	on item.MainItemId=fts.ItemId   
	 left join    [Loyalty_Shell_1].[dbo].[CRM_Member] cm  on cp.BuyingUnitInternalKey=cm.BuyingUnitInternalKey
	  left join   report_data.[dbo].[CRM_MemberStoreAssign_shell] cmsa 
	    on cm.MemberInternalKey=cmsa.MemberInternalKey and cmsa.StoreTypeId=2 and cmsa.MatrixMemberId=@MatrixMemberId
	
	
		left join 	[report_data].[dbo].store_gs    s on s.StoreInternalKey=cmsa.StoreInternalKey
		    and s.MatrixMemberId=@MatrixMemberId
    
  where convert(varchar,fth.CreatedDate,120)>=@createDate_begin and 
   convert(varchar,fth.CreatedDate,120)<@createDate_end 
    and ftc.BusinessDate>=@createDate_begin and ftc.BusinessDate<=@business_end   
   --and item.MainItemId is not null 
    order by fth.CreatedDate';
	
	set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_pre);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
	set @sql_text = replace(@sql_text,'@createDate_begin',''''+@createDate_begin+'''');
	set @sql_text = replace(@sql_text,'@createDate_end',''''+@createDate_end+'''');
	set @sql_text = replace(@sql_text,'@business_end',''''+@business_end+'''');
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);

	exec(@sql_text);
	set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_cur);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
	set @sql_text = replace(@sql_text,'@createDate_begin',''''+@createDate_begin+'''');
	set @sql_text = replace(@sql_text,'@createDate_end',''''+@createDate_end+'''');
	set @sql_text = replace(@sql_text,'@business_end',''''+@business_end+'''');
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);

	exec(@sql_text);


	print @table
 set  @table='R1_tran';
set  @Expoprtfilename=@filepath+@table+'\'+@table+@createDate_begin+'-'+@business_end+'.csv';
 
exec  report_data.[dbo].est_export_cvs @table,@Server,@Expoprtfilename;	

 -- print @tran_detail_reward_point_sql;
--  insert into  report_data.[dbo].[tran_detail_reward_point]  exec @tran_detail_reward_point_sql

--  R1_1  discount table 

  delete report_data.[dbo].[R1_1_tran_discount] ;
 set @sql_text_org=N'insert into  report_data.[dbo].[R1_1_tran_discount] (
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
	 ,phpr.PromotionGroupId                                 --25促销组
	 ,substring(phpr.ExternalReferenceID,1,8)                             --26 外部促销id
	 ,convert(varchar,fth.CreatedDate,120)                  --27 上传日期
	--  ,ftprd1.PromotionId as pointPromotionId        --获得积分促销id
 from 
		  [ATD_Shell].dbo.FO_TranHeader201704 fth
	 
		
		  
		  inner  join [ATD_Shell].[dbo].[FO_TranCollection] ftc
		 
on ftc.CollectionInternalKey=fth.CollectionInternalKey
 inner  join  [report_data].[dbo].store_gs store on store.storeid=ftc.storeid
   left join  Loyalty_Shell_1. [dbo].[CRM_POSTran] cp 
    on cp.TranId=fth.TranId and cp.PosDateTime=ftc.BusinessDate and cp.StoreInternalKey=store.StoreInternalKey
	and  cp.MatrixMemberId=@MatrixMemberId
--	inner join [ATD_Shell].dbo.FO_TranSale201704 fts
--	on fts.TicketInternalKey=fth.TicketInternalKey
		left join ((select  distinct  TicketInternalKey, ftprd1.PromotionId ,    ftprd1.RewardValue   as RewardValue , entityid 
  from  [ATD_Shell].dbo.FO_TranPromotionRewardApportionment201704 ftprd1 where RewardMethodId=4) ) ftprd
	on ftprd.TicketInternalKey=fth.TicketInternalKey   --and ftprd.EntityId=fts.ItemId 
  -- left join (select  distinct  TicketInternalKey, ftprd1.PromotionId ,ftprd1.RewardValue , entityid 
--  from  [ATD_Shell].dbo.FO_TranPromotionRewardApportionment201704 ftprd1 where RewardMethodId=1) ftprd1
 -- on ftprd1.TicketInternalKey=fts.TicketInternalKey  --and ftprd1.EntityId=fts.ItemId 
   inner join [Loyalty_Shell_1].[dbo].[PromotionHeader_PR] phpr 
	on phpr.PromotionHeaderId=ftprd.PromotionId  and  phpr.MatrixMemberId=@MatrixMemberId
	left join  [report_data].[dbo].item_cat  item 
	on item.MainItemId=ftprd.EntityId
	 left join    [Loyalty_Shell_1].[dbo].[CRM_Member] cm  on cp.BuyingUnitInternalKey=cm.BuyingUnitInternalKey
	 left join   report_data.[dbo].[CRM_MemberStoreAssign_shell] cmsa 
	    on cm.MemberInternalKey=cmsa.MemberInternalKey and cmsa.StoreTypeId=2 and   cmsa.MatrixMemberId=@MatrixMemberId
	  left join 	[report_data].[dbo].store_gs    s on s.StoreInternalKey=cmsa.StoreInternalKey
       and  s.MatrixMemberId=@MatrixMemberId
  where  convert(varchar,fth.CreatedDate,120)>=@createDate_begin and 
   convert(varchar,fth.CreatedDate,120)<@createDate_end  and ftc.BusinessDate>=@createDate_begin and ftc.BusinessDate<=@business_end  
    order by fth.CreatedDate';
	set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_pre);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
	set @sql_text = replace(@sql_text,'@createDate_begin',''''+@createDate_begin+'''');
	set @sql_text = replace(@sql_text,'@createDate_end',''''+@createDate_end+'''');
	set @sql_text = replace(@sql_text,'@business_end',''''+@business_end+'''');
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);

	exec(@sql_text);
	set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_cur);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
	set @sql_text = replace(@sql_text,'@createDate_begin',''''+@createDate_begin+'''');
	set @sql_text = replace(@sql_text,'@createDate_end',''''+@createDate_end+'''');
	set @sql_text = replace(@sql_text,'@business_end',''''+@business_end+'''');
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);

	exec(@sql_text);
	 
	set  @table='R1_1_tran_discount';
    print @table
	set  @Expoprtfilename=@filepath+@table+'\'+@table+@createDate_begin+'-'+@business_end+'.csv';

exec  report_data.[dbo].est_export_cvs @table,@Server,@Expoprtfilename;	
------------discount------------------------
----------------reward point---------------------
delete report_data.[dbo].[r1_2_tran_reward] ;
set @sql_text_org=N'insert into  report_data.[dbo].[r1_2_tran_reward] (
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
	 ,phpr.PromotionGroupId                                 --25促销组
	 
	 ,substring(phpr.ExternalReferenceID,1,8)                             --26 外部促销id
	 ,convert(varchar,fth.CreatedDate,120)                  --27 上传日期

   from   
		   [ATD_Shell].dbo.FO_TranHeader201704 fth
			  inner  join [ATD_Shell].[dbo].[FO_TranCollection] ftc
		 
on ftc.CollectionInternalKey=fth.CollectionInternalKey
 inner  join  [report_data].[dbo].store_gs store on store.storeid=ftc.storeid and store.MatrixMemberId=@MatrixMemberId
   left join  Loyalty_Shell_1. [dbo].[CRM_POSTran] cp 
    on cp.TranId=fth.TranId and cp.PosDateTime=ftc.BusinessDate and cp.StoreInternalKey=store.StoreInternalKey
	  and  cp.MatrixMemberId=@MatrixMemberId
	--inner join [ATD_Shell].dbo.FO_TranSale201704 fts
---	on fts.TicketInternalKey=fth.TicketInternalKey
		
   left join (select  distinct  TicketInternalKey, ftprd1.PromotionId ,ftprd1.RewardValue , entityid 
  from  [ATD_Shell].dbo.FO_TranPromotionRewardApportionment201704 ftprd1 where RewardMethodId=1) ftprd1
  on ftprd1.TicketInternalKey=fth.TicketInternalKey   --and ftprd1.EntityId=fts.ItemId 
    left join [Loyalty_Shell_1].[dbo].[PromotionHeader_PR] phpr 
	on phpr.PromotionHeaderId=ftprd1.PromotionId and phpr.MatrixMemberId=@MatrixMemberId
	left join  [report_data].[dbo].item_cat  item    on item.MainItemId=ftprd1.EntityId   
	left join    [Loyalty_Shell_1].[dbo].[CRM_Member] cm  on cp.BuyingUnitInternalKey=cm.BuyingUnitInternalKey
	 left join   report_data.dbo.CRM_MemberStoreAssign_shell cmsa 
	    on cm.MemberInternalKey=cmsa.MemberInternalKey and cmsa.StoreTypeId=2 and cmsa.MatrixMemberId=@MatrixMemberId
	left join 	[report_data].[dbo].store_gs    s on s.StoreInternalKey=cmsa.StoreInternalKey
        and  s.MatrixMemberId=@MatrixMemberId
  where  cp.ClubCardId is not null and  convert(varchar,fth.CreatedDate,120)>=@createDate_begin and 
   convert(varchar,fth.CreatedDate,120)<@createDate_end and ftc.BusinessDate>=@createDate_begin and ftc.BusinessDate<=@business_end and phpr.PromotionHeaderId is not null  
    order by fth.CreatedDate';
	set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_pre);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
	set @sql_text = replace(@sql_text,'@createDate_begin',''''+@createDate_begin+'''');
	set @sql_text = replace(@sql_text,'@createDate_end',''''+@createDate_end+''''); 
	set @sql_text = replace(@sql_text,'@business_end',''''+@business_end+'''');
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);

	print @sql_text;
	exec(@sql_text);
	set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_cur);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
	set @sql_text = replace(@sql_text,'@createDate_begin',''''+@createDate_begin+'''');
	set @sql_text = replace(@sql_text,'@createDate_end',''''+@createDate_end+'''');
	set @sql_text = replace(@sql_text,'@business_end',''''+@business_end+'''');
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);

	exec(@sql_text);
	
	set  @table='R1_2_tran_reward';
   set  @Expoprtfilename=@filepath+@table+'\'+@table+@createDate_begin+'-'+@business_end+'.csv';
	print @table
    exec  report_data.[dbo].est_export_cvs @table,@Server,@Expoprtfilename;	
------------------------------------
 --R2-油站积分兑换 
 -- set @redemption_point_sql=
 delete  report_data. [dbo].R2_redemption_point;
set  @sql_text_org=N'insert into report_data. [dbo].R2_redemption_point
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
,store.comp as sal_com                                  --6公司代码
,store.compid as sal_com_id                             --6.1公司代码
  ,store.storeid                 --4 油站代码
 ,store.storename as stor       -- 5油站名称
 ,  store.city   as city,                        --7城市
    ftc.CashierId ,                             --8cashierid
	  fth.TranId  ,                             --9交易流水号
  convert(varchar(10), ftc.BusinessDate,120) businessDate,        --10营业日
   convert(varchar(10),ftc.createddate,120) trandate,             --11交易日期
   convert(varchar(8),ftc.createddate,8)  trantime,               --12交易时间
   ftc.TillId   posid   ,                                      --13
   item.firsttype,                               --14商品类型
  item.midtypeCode,                                 --15 商品中类
 item.midtype,                                 --15.1 商品中类
 item.mainitemid,                               --16
  item.FullName,							   -- 17 商品  
  fts.Qty,			     				   --18数量
  	ftprd.rewardValue*@bal  as      Redemption_quantity,                  --19积分兑换数量 
  ftprd.rewardValue  redemption ,           --20积分抵扣金额
	 ftprd.PromotionId,                                  --21
	 phpr.PromotionGroupId                               --22
	 ,substring(phpr.ExternalReferenceID,1,8)                          --23 外部促销id
	 ,convert(varchar,cp.CreatedAt,120)                 --24 上传日期

   from  Loyalty_Shell_1. [dbo].[CRM_POSTran] cp
    inner join   [report_data].[dbo].store_gs  store1 on store1.StoreInternalKey=cp.StoreInternalKey  and cp.MatrixMemberId=@MatrixMemberId
    and store1.MatrixMemberId=@MatrixMemberId    inner  join [ATD_Shell].[dbo].[FO_TranCollection] ftc  on ftc.BusinessDate=cp.PosDateTime  and store1.storeid=ftc.StoreId
 	  inner join	   [ATD_Shell].dbo.FO_TranHeader201704    fth
    on fth.CollectionInternalKey=ftc.CollectionInternalKey  and fth.TranId=cp.TranId  
inner  join  [ATD_Shell].[dbo].[FO_TranSale201704] fts 	on fts.TicketInternalKey=fth.TicketInternalKey 
inner join  [ATD_Shell].[dbo].[FO_TranPromotionRewardApportionment201704] ftprd on ftprd.TicketInternalKey=fts.TicketInternalKey and ftprd.EntityId=fts.ItemId and ftprd.RewardMethodId=5
    left join [Loyalty_Shell_1].[dbo].[PromotionHeader_PR] phpr 	on phpr.PromotionHeaderId=ftprd.PromotionId
	left join  [report_data].[dbo].item_cat  item 	on item.MainItemId=fts.ItemId   
	 left join    [Loyalty_Shell_1].[dbo].[CRM_Member] cm  on cp.BuyingUnitInternalKey=cm.BuyingUnitInternalKey
	  left join    report_data.dbo.CRM_MemberStoreAssign_shell cmsa 	    on cm.MemberInternalKey=cmsa.MemberInternalKey and cmsa.StoreTypeId=2 and cmsa.MatrixMemberId=@MatrixMemberId
		left join 	[report_data].[dbo].store_gs    s on s.StoreInternalKey=cmsa.StoreInternalKey  	 and s.MatrixMemberId=@MatrixMemberId
  left join [report_data].[dbo].store_gs  store on cp.StoreInternalKey=store.StoreInternalKey and store.MatrixMemberId=@MatrixMemberId
  where         convert(varchar,cp.CreatedAt,120)>=@createDate_begin
  and  convert(varchar,cp.CreatedAt,120)<@createDate_end and ftc.BusinessDate>=@createDate_begin and ftc.BusinessDate<=@business_end
   and cp.MatrixMemberId=@MatrixMemberId
  order by cp.CreatedAt';
 set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_pre);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);

	set @sql_text = replace(@sql_text,'@createDate_begin',''''+@createDate_begin+'''');
	set @sql_text = replace(@sql_text,'@createDate_end',''''+@createDate_end+'''');
	set @sql_text = replace(@sql_text,'@business_end',''''+@business_end+'''');
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);

	print @sql_text
	exec(@sql_text);
	set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_cur);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);

	set @sql_text = replace(@sql_text,'@createDate_begin',''''+@createDate_begin+'''');
	set @sql_text = replace(@sql_text,'@createDate_end',''''+@createDate_end+'''');
	set @sql_text = replace(@sql_text,'@business_end',''''+@business_end+'''');
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);

	exec(@sql_text);
   set  @table='R2_redemption_point'
  set  @Expoprtfilename=@filepath+@table+'\'+@table+@createDate_begin+'-'+@business_end+'.csv';
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
	,s.city                                --城市
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
    on cp.TranId=fth.TranId and ftc.BusinessDate=cp.PosDateTime 	and cp.StoreInternalKey=store1.StoreInternalKey
   left join    [Loyalty_Shell_1].[dbo].[CRM_Member] cm  on cp.BuyingUnitInternalKey=cm.BuyingUnitInternalKey
  left join    report_data.dbo.CRM_MemberStoreAssign_shell cmsa 	    on cm.MemberInternalKey=cmsa.MemberInternalKey  and cmsa.StoreTypeId=2
    left join    [ATD_Shell].[dbo].[FO_TranTender201704]  ttender    on fth.TicketInternalKey=ttender.TicketInternalKey
     left join [ATD_Shell].[dbo].[Tender_ALL] tender on ttender.StoreTenderId=tender.TenderId
left join 	[report_data].[dbo].store_gs    s on s.storeid=ftc.StoreId
where convert(varchar,fth.CreatedDate,120)>=@createDate_begin 
  and convert(varchar,fth.CreatedDate,120)<@createDate_end and ftc.BusinessDate>=@createDate_begin and ftc.BusinessDate<=@business_end
   and ftc.TranTypeId in (20,23) and ttender.TicketInternalKey is not null
 order by fth.CreatedDate'

 set @sql_text=@sql_text_org;

	set @sql_text = replace(@sql_text,'201704',@tableDate_pre);

	set @sql_text = replace(@sql_text,'@createDate_begin',''''+@createDate_begin+'''');
	set @sql_text = replace(@sql_text,'@createDate_end',''''+@createDate_end+'''');
	set @sql_text = replace(@sql_text,'@business_end',''''+@business_end+'''');
	set @sql_text = replace(@sql_text,'@bal',@bal);
set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);

	exec(@sql_text);
	set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_cur);
	set @sql_text = replace(@sql_text,'@createDate_begin',''''+@createDate_begin+'''');
	set @sql_text = replace(@sql_text,'@createDate_end',''''+@createDate_end+'''');
	set @sql_text = replace(@sql_text,'@business_end',''''+@business_end+'''');
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);

	exec(@sql_text);
	--	print @sql_text;
 set  @table='r7_payment_tender';
set  @Expoprtfilename=@filepath+@table+'\'+@table+@createDate_begin+'-'+@business_end+'.csv';

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
,s.comp as regcomp                  --2会员注册公司
,s.storename regstore                       --3会员默认油站

,store.storeid                                   --4油站代码
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
	  left join    report_data.dbo.CRM_MemberStoreAssign_shell cmsa 
	    on cm.MemberInternalKey=cmsa.MemberInternalKey and cmsa.StoreTypeId=2
		left join 	[report_data].[dbo].store_gs    s on s.StoreInternalKey=cmsa.StoreInternalKey
   left join [report_data].[dbo].store_gs  store on cmsa.StoreInternalKey=store.StoreInternalKey
   left join   Loyalty_Shell_1. [dbo].[CRM_POSTran] cp on cp.POSTranInternalKey=paa.PosTranInternalKey
 where
  (posid=-66 or  posid=-99)
  and cp.PosDateTime>=convert(datetime,@createDate_begin,120) 
 and cp.PosDateTime<convert(datetime,@createDate_end1,120) 
 order by cp.PosDateTime';

 set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@TableDate_cur);
	set @sql_text = replace(@sql_text,'@createDate_begin',''''+@createDate_begin+'''');
	set @sql_text = replace(@sql_text,'@createDate_end1',''''+@createDate_end1+'''');
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
	print @sql_text;
	exec(@sql_text);
	
 set  @table='r9_adjust';
 print @table;
set  @Expoprtfilename=@filepath+@table+'\'+@table+@createDate_begin+'-'+@business_end+'.csv';
exec  report_data.[dbo].est_export_cvs @table,@Server,@Expoprtfilename;	


  
   ----R10-member list
   --insert into member_list
 --  delete report_data.dbo.R10_member_list;  2017.04.26 
set @sql_text_org=N'    INSERT INTO report_data.[dbo].[r10_member_list]
           ([member_card_no]    --1
		   ,member_reg_comp_code   --2
		   ,member_reg_store_code   --3
		   ,member_reg_store         --4
           ,[reg_date]               --5
           ,[jv_segment]             --5
           ,[legal]                  --6
           ,[city]                   --7
           ,[province]               --8
           ,[reg_channel]            --9
		   ,birthday                  --10
           ,[gender]                 --11
           ,[phone]                  --12
           ,[balance]                --13
           ,[status])                --14    
		   select  cm.externalmemberkey          --1会员号码
		  , s.compid    compid            --2.0
,s.storeid   storeid           --3.0会员注册油站     
,s.storename  regstore         --3会员注册默认油站
,convert(varchar(10),cm.StartDate,120)          --4 -注册日期
 ,'''+'HB'+''' jv_seg               --5 所属JV会员组         
,cs.SegmentDescription 					-- 6公司代码
, crmb.city  city								    --7所在城市
, sp.StateName  prov								    --8所属省份
,crmb.POBox regchannel --9注册渠道
,convert(varchar(10),cm.birthdate,120)				--10
,case when cm.Gender=1 then N'''+N'男'+''' else N'''+N'女'+''' end  as xb --11
,cm.MobilePhoneNumber           --手机号码      --12
 ,buaa.Balance                               -- 会员帐户余额     --13  
,cm.RestrictionId                           --卡状态        --14
     from       [Loyalty_Shell_1].[dbo].[CRM_Member] cm  
	  left join    report_data.[dbo].[CRM_MemberStoreAssign_shell] cmsa 
	    on cm.MemberInternalKey=cmsa.MemberInternalKey and cmsa.StoreTypeId=2 
		left join 	[report_data].[dbo].store_gs    s on s.StoreInternalKey=cmsa.StoreInternalKey and   s.MatrixMemberId=cmsa.MatrixMemberId
   left join [report_data].[dbo].store_gs  store on cmsa.StoreInternalKey=store.StoreInternalKey and   cmsa.MatrixMemberId=store.MatrixMemberId
   left join   [Loyalty_Shell_1].[dbo].[CRM_BuyingUnitAccountsActivity]   buaa 
    on buaa.BuyingUnitInternalKey=cm.BuyingUnitInternalKey AND buaa.AccountInternalKey=2  
  left join  [Loyalty_Shell_1].[dbo].[CRM_Clubcard]  cc on  cc.ClubCardId=cm.ExternalMemberKey  and cmsa.MatrixMemberId=cc.MatrixMemberId
  left join  [Loyalty_Shell_1].[dbo].CRM_BuyingUnit crmb on cm.BuyingUnitInternalKey=crmb.BuyingUnitInternalKey 
  --and  crmb.MatrixMemberId=cc.MatrixMemberId
  left join  [Loyalty_Shell_1].[dbo].[State_MP]  sp on crmb.State=sp.StateId and sp.LanguageId=8
 inner join Loyalty_Shell_1. [dbo].[CRM_MemberSegment] cms on cms.MemberInternalKey=cm.MemberInternalKey
                  and  cms.SegmentInternalKey in (19,20,21,22)   and  cms.MatrixMemberId=@MatrixMemberId
 inner join  Loyalty_Shell_1.[dbo].[CRM_Segment] cs on cs.SegmentInternalKey=cms.SegmentInternalKey and  cs.MatrixMemberId=cms.MatrixMemberId
   where  cm.externalmemberkey  is not null   --and convert(varchar,cm.StartDate,120)  >=@createDate_begin
  -- and convert(varchar,cm.StartDate,120)  <@createDate_end 
  order by cm.StartDate'
 
  set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@TableDate_cur);
	set @sql_text = replace(@sql_text,'@createDate_begin',''''+@createDate_begin+'''');
	set @sql_text = replace(@sql_text,'@createDate_end',''''+@createDate_end+'''');
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
		set @sql_text = replace(@sql_text,'@business_end',''''+@business_end+'''');
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);

/**	exec(@sql_text);
	   set  @table='r10_member_list';
set  @Expoprtfilename=@filepath+@table+'\'+@table+@createDate_begin+'-'+@business_end+'.csv';
exec  report_data.[dbo].est_export_cvs @table,@Server,@Expoprtfilename;	
**/
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
 select ROW_NUMBER() over ( partition by  ftc.StoreId,store.storename,store.compID,store.comp order by sum(ftprd.RewardValue) desc )
AS  Rownum                                 --1
 , convert(varchar(10),ftc.BusinessDate,120)  tran_date                      --2
 ,ftc.StoreId                              --3
 ,store.storename                          --4
 ,store.comp                               --5
 ,store.compID                               --6
 ,cm.ExternalMemberKey                    --7
 , sum( case when item.midtypeCode=1001 then 1  else 0 end ) aspetrol_amount   -- sum( case when item.midtypeCode=1001 then ftprd.RewardValue else 0 end ) aspetrol_amount  --8
 ,  sum( case when item.midtypeCode=1002 then 1 else 0 end ) as diesel_oil_amount   --sum( case when item.midtypeCode=1002 then ftprd.RewardValue else 0 end ) as diesel_oil_amount  --9
 ,sum( case when item.midtypeCode not in (1002,1001)  then  1 else 0 end ) as conven_goods_amount     --sum( case when item.midtypeCode not in (1002,1001)  then ftprd.RewardValue else 0 end ) as conven_goods_amount --10
 ,   count (1)   as total_amount   --sum(ftprd.RewardValue) as total_amount   --11
   from   [ATD_Shell].dbo.FO_TranPromotionRewardApportionment201704  ftprd 
   left join     [ATD_Shell].dbo.FO_TranHeader201704  fth on fth.TicketInternalKey=ftprd.TicketInternalKey
  inner  join    [ATD_Shell].[dbo].[FO_TranCollection] ftc on ftc.CollectionInternalKey=fth.CollectionInternalKey
   left join    loyalty_shell_1. [dbo].[CRM_POSTran] cp on cp.TranId=fth.TranId 
    and cp.PosDateTime=ftc.BusinessDate
	inner join    [report_data].[dbo].item_cat  item  	on item.MainItemId=ftprd.EntityId 
	inner join [report_data].[dbo].store_gs  store on cp.StoreInternalKey=store.StoreInternalKey  and ftc.StoreId=store.storeid
	and store.MatrixMemberId=cp.MatrixMemberId
	inner  join    [Loyalty_Shell_1].[dbo].[CRM_Member] cm  on cp.BuyingUnitInternalKey=cm.BuyingUnitInternalKey
 where ftprd.RewardMethodId=1  and   convert(varchar,fth.CreatedDate,120)>=@createDate_begin 
  and convert(varchar,fth.CreatedDate,120)<=@createDate_end and ftc.BusinessDate>=@createDate_begin and ftc.BusinessDate<=@business_end
 group by  ftc.BusinessDate,ftc.StoreId,store.storename,store.compID,store.comp,cm.ExternalMemberKey)a 
 where rownum<=20
  order by  StoreId, storename, compID, comp,rownum  '
     set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@TableDate_cur);
	set @sql_text = replace(@sql_text,'@createDate_begin',''''+@createDate_begin+'''');
	set @sql_text = replace(@sql_text,'@createDate_end',''''+@createDate_end+'''');
	set @sql_text = replace(@sql_text,'@bal',@bal);
		set @sql_text = replace(@sql_text,'@business_end',''''+@business_end+'''');
		set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
	print @sql_text;
	exec(@sql_text);
	
   set  @table='R10_1_fraud_control';
   print @table
set  @Expoprtfilename=@filepath+@table+'\'+@table+@createDate_begin+'-'+@business_end+'.csv';
exec  report_data.[dbo].est_export_cvs @table,@Server,@Expoprtfilename;	



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
  select  distinct substring(phpr.ExternalReferenceID,1,8)       ---1促销ID
,phpr.ExternalGroupId                   --2促销组ID
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
	on phpr.PromotionHeaderId=ftprd1.PromotionId	
   where convert(varchar,fth.CreatedDate,120)>=@createDate_begin and 
   convert(varchar,fth.CreatedDate,120)<@createDate_end and ftc.BusinessDate>=@createDate_begin and ftc.BusinessDate<=@business_end 
 order by phpr.ExternalGroupId,substring(phpr.ExternalReferenceID,1,8)    DESC  ';
  set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@TableDate_cur);
	set @sql_text = replace(@sql_text,'@createDate_begin',''''+@createDate_begin+'''');
	set @sql_text = replace(@sql_text,'@createDate_end',''''+@createDate_end+'''');
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
		set @sql_text = replace(@sql_text,'@business_end',''''+@business_end+'''');

	exec(@sql_text);
	
   set  @table='R13_promotion_list';
   print  @table;
set  @Expoprtfilename=@filepath+@table+'\'+@table+@createDate_begin+'-'+@business_end+'.csv';
exec  report_data.[dbo].est_export_cvs @table,@Server,@Expoprtfilename;	

   end;


GO
