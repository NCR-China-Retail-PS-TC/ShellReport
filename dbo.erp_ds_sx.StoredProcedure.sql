USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[erp_ds_sx]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/****** Object:  StoredProcedure [dbo].[est]    Script Date: 2017/3/2 18:01:20 ******/

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
--2020-11-17  CR333–陕西Loyalty积分接口处理逻辑调整
---陕西异业积分数据在Loyalty积分接口处理逻辑调整和陕西R 报表新增
-- 根据CR405 陕西折扣数据直接传输ERP接口
--Loyalty按站、按天、按SKU所属中类、按销项税率、按促销类型（油品油非互动和油非互动外、非油品油非互动和油非互动外）生成数据直接传输至ERP
-- 20211029  V1.2
-- exec erp_ds_sx '2021-10-19'
-- =============================================
CREATE PROCEDURE [dbo].[erp_ds_sx]
	 @CreatedDate varchar(10)='2017-03-01'   --yyyy-mm-dd
	AS
BEGIN
   
		 		 
		 declare @bal int =50; --per 20  point  for 1 rmb
		 declare @createDateNextday varchar(10)= dateadd( day,1,convert(date,@createddate,120))
    declare @tableDate_cur varchar(6) ,@tableDate_pre varchar(6) 
	,@atd_Server nvarchar(max) 	
	,@ServerHost nvarchar(max)
	,@loyalty_server varchar(max)
	,@sql_text  nvarchar(max)
	,@sql_text_org nvarchar(max)
	, @MatrixMemberId int
	declare @RetailerId varchar(10)='2';	
	  select @MatrixMemberId=MatrixMemberId from  RetailCode_MP rcmp  	 
	   where rcmp.RetailerId=@RetailerId   ;   ----sx RetailerId   is 2
	set @TableDate_cur=SUBSTRING(REPLACE(@CreatedDate,'-',''),1,6) --设置年月
	set @TableDate_pre=SUBSTRING(REPLACE(convert( varchar,dateadd(month,-1,@CreatedDate),120),'-',''),1,6) --设置年月 数据前一个月
	
		select @atd_Server=c.paraValue0   from dbo.param_config c  where c.paraName='atd_Server';
	select @ServerHost=c.paraValue0   from dbo.param_config c  where c.paraName='ServerHost';
	select @loyalty_server=c.paraValue0   from dbo.param_config c  where c.paraName='loyalty_server';
		

 -- print @tran_detail_reward_point_sql;
--  insert into  report_data.[dbo].[tran_detail_reward_point]  exec @tran_detail_reward_point_sql

--  R1_1  discount table 

	 
	
------------discount------------------------
----------------reward point---------------------
truncate  table  report_data.[dbo].[DS_r1_2_tran_reward] 

set @sql_text_org=N'
select  distinct  TicketInternalKey, ftprd1.PromotionId ,ftprd1.RewardValue , entityid 
 into #ftpra1  from  [ATD_Shell].dbo.FO_TranPromotionRewardApportionment201704 ftprd1 where  RewardMethodId=1 and RewardId=100
insert into  report_data.[dbo].[DS_r1_2_tran_reward] (
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
 select  fc.CardId           --1会员号码

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
left join ATD_Shell..FO_TranCard201704 fc on fth.TicketInternalKey=fc.TicketInternalKey  
 inner  join  [report_data].[dbo].store_gs store on store.storeid=ftc.storeid and store.MatrixMemberId=@MatrixMemberId
  
	--inner join [ATD_Shell].dbo.FO_TranSale201704 fts
---	on fts.TicketInternalKey=fth.TicketInternalKey
   left join  #ftpra1 ftprd1
  on ftprd1.TicketInternalKey=fth.TicketInternalKey   --and ftprd1.EntityId=fts.ItemId 
    left join report_data.[dbo].[PromotionHeader_PR] phpr 
	on phpr.PromotionHeaderId=ftprd1.PromotionId and phpr.MatrixMemberId=@MatrixMemberId
	left join  [report_data].[dbo].item_cat  item    on item.MainItemId=ftprd1.EntityId  and item.MatrixMemberId=@MatrixMemberId  
	left join    [Loyalty_Shell_1].[dbo].[CRM_Member] cm   on cm.ExternalMemberKey=fc.CardId
			 left join   report_data.[dbo].[v_get_reg_compAndStore]   s   on s.BuyingUnitInternalKey=cm.BuyingUnitInternalKey 
			 and  s.MatrixMemberId=@MatrixMemberId  --首次注册油站
--left join RetailCode_MP  rc on rc.MatrixMemberId=cp.MatrixMemberId
  where fth.CreatedDate>=convert(date,@createdDate,120)   and  fth.CreatedDate<convert(date,@createDateNextday,120)   
     	 and phpr.PromotionHeaderId is not null
		  --and      rc.RetailerId=@retailerID
		  and      ftc.RetailerId=@retailerID
		  --and s.StoreType is not null  
		and  s.compid is not null
    order by fth.CreatedDate';
	set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_pre);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
 	set @sql_text = replace(@sql_text,'@RetailerId',''''+@RetailerId+'''');
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
	set @sql_text = replace(@sql_text,'@CreatedDate',''''+@CreatedDate+'''');
	set @sql_text = replace(@sql_text,'@createDateNextday',''''+@createDateNextday+'''');
	print @sql_text;
		if OBJECT_ID('tempdb..#ftprd1') is not null 
  drop  table #ftprd1
	exec(@sql_text);
	set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_cur);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
 	set @sql_text = replace(@sql_text,'@RetailerId' ,''''+@RetailerId+'''');
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
	set @sql_text = replace(@sql_text,'@CreatedDate',''''+@CreatedDate+'''');
	set @sql_text = replace(@sql_text,'@createDateNextday',''''+@createDateNextday+'''');
	select @sql_text
		if OBJECT_ID('tempdb..#ftprd1') is not null 
  drop  table #ftprd1
	exec(@sql_text);
	
	 
------------------------------------
 --R2-油站积分兑换 
 -- set @redemption_point_sql=
truncate  table report_data. [dbo].DS_R2_redemption_point
 --where business_date >=@CreatedDate_begin   and business_date<=@business_end
 --       and   create_date>= @CreatedDate_begin
--		 and   create_date <@CreatedDate_end ;
set  @sql_text_org=N'insert into report_data. [dbo].DS_R2_redemption_point
          ([member_card_no]            --1
          , member_reg_comp_code          --2.0
          ,  member_reg_comp				  --3
          ,  member_reg_store_code         --4
          ,  member_reg_store              --5
          ,  legal_code                    --6
          ,  legal_name                    --7
          ,  store_code                    --8 
          ,  store_name                    --9
           ,[city]                     --10
           ,[cashier_id]               --11
           ,[transaction_no]           --12
           ,[business_date]            --13
           ,[transaction_date]         --14
           ,[transaction_time]         --15
           ,[posid]                    --16
           ,[item_cat]                 --17
           ,[item_cat_mid]             --18
            ,item_cat_mid_name        --19
           ,[item]                     --20
		   ,[item_name]                --21
           ,[quantity]                 --22
           ,[redemption_point_q]       --23
		   ,[redemption_point_amount]  --24
		    ,redemption_point_je --25  积分折算金额
           
   		   ,redem_ce  --26差额
           ,[promotion_id]             --27
           ,[promotion_group]         --28
		    ,promtion_ref                --29
		   ,create_date                  --30
		   ,RetailerId                       --31
		    ,Storetype                   --32
           ,TaxCode                      --33
           ,PromotionType                --34
		  
		   )
select   ft.CardId,                                  --1会员号码

 s.compid    compid            --2.0
,s.comp      regcomp           --3会员注册公司
,s.storeid   storeid           --4会员注册油站     
,s.storename  regstore         --5会员注册默认油站
,store.compid as sal_com_id                                   --6公司代码
,store.comp as sal_com                             --7公司代码
  ,store.storeid                 --8 油站代码
 ,store.storename as stor       -- 9油站名称
 ,  store.city   as city,                        --10城市
    ftc.CashierId ,                             --11cashierid
	  fth.TranId  ,                             --12交易流水号
  convert(varchar(10), ftc.BusinessDate,120) businessDate,        --13营业日
   convert(varchar(10),ftc.createddate,120) trandate,             --14交易日期
   convert(varchar(8),ftc.createddate,8)  trantime,               --15交易时间
   ftc.TillId   posid   ,                                      --16
   item.firsttype,                                  --17商品类型
  item.midtypeCode,                                 --18 商品中类
 item.midtype,                                      --19 商品中类
ftprd.EntityId,                                   --20
  item.FullName,							        -- 21 商品  
  ftprd.RewardedQty,			     				            --22数量
 case when ftprds.RewardValue=0 then ftpma.AdjustmentValue else 
    cast(ftprd.rewardValue/ftprds.RewardValue*ftpma.AdjustmentValue as  decimal(10,2))  end    Redemption_quantity,   --23                --19积分兑换数量 
      case when ftprds.RewardValue=0 then ftpma.AdjustmentValue/@bal else 
	     cast(  ftprd.rewardValue/ftprds.RewardValue*ftpma.AdjustmentValue/@bal  as   decimal(10,2)) end  as redemption_point_je , --24  积分折算金额
 cast( ftprd.rewardValue as  decimal(10,2))  redemption ,             --25积分抵扣金额 
-1*case  when  ftprds.RewardValue=0 then  -1*ftpma.AdjustmentValue/@bal else 
   cast(ftprd.rewardValue-ftprd.rewardValue/ftprds.RewardValue*ftpma.AdjustmentValue /@bal  as   decimal(10,2))
   end   as    redem_ce   -- 26差额 
   ' 
  set @sql_text_org=@sql_text_org+N'
  	 ,ftprd.PromotionId                                  --27
	 ,phpr.ExternalGroupId                             --28
	 ,substring(phpr.ExternalReferenceID,1,8)                          --29 外部促销
	 ,convert(varchar(10),fth.CreatedDate,120)                --30 上传日期
	 , @RetailerId                                 --31
	,	    store.Storetype                     --32
     ,      item.TaxCode                    --33
     ,      PromotionType                 --   34

	 	
  '
  set @sql_text_org=@sql_text_org+N'  from   [ATD_Shell].[dbo].[FO_TranCollection] ftc  --Loyalty_Shell_1. [dbo].[CRM_POSTran] cp
	 inner  join [ATD_Shell].dbo.FO_TranHeader201704    fth  on fth.CollectionInternalKey=ftc.CollectionInternalKey
     inner join   [report_data].[dbo].store_gs  store1 on store1.storeid=ftc.StoreId  and store1.MatrixMemberId=@MatrixMemberId
 	 left join  [ATD_Shell].[dbo].fo_Trancard201704   ft on ft.TicketInternalKey=fth.TicketInternalKey 
inner join (
    select   ftprd1.TicketInternalKey, ftprd1.PromotionId ,sum(ftprd1.RewardValue) RewardValue  
    from  [ATD_Shell].[dbo].[FO_TranPromotionRewardApportionment201704] ftprd1  
	   where RewardMethodId in (5,3) 
	   group by ftprd1.TicketInternalKey, ftprd1.PromotionId     ) ftprds    --having sum(ftprd1.RewardValue)<>0  9999  userd for point shop
	   on ftprds.TicketInternalKey=fth.TicketInternalKey
	inner join      [ATD_Shell].[dbo].[FO_TranPromotionRewardApportionment201704] ftprd  
	-- on ftprd.TicketInternalKey=fth.TicketInternalKey  
	 on  ftprds.TicketInternalKey=ftprd.TicketInternalKey and ftprd.PromotionId=ftprds.PromotionId
	  and ftprd.RewardMethodId in (5,3) 

	inner join   [ATD_Shell].[dbo].[FO_TranPromotionMemberAccount201704] ftpma 
	on ftprds.TicketInternalKey=ftpma.TicketInternalKey and ftpma.PromotionId=ftprds.PromotionId'

 set @sql_text_org=@sql_text_org+'   
  left join report_data.[dbo].[PromotionHeader_PR] phpr 	on phpr.PromotionHeaderId=ftprd.PromotionId  and phpr.MatrixMemberId=@MatrixMemberId
	left join  [report_data].[dbo].item_cat  item 	on item.MainItemId=ftprd.EntityId   and item.MatrixMemberId=@MatrixMemberId 
	 left join    [Loyalty_Shell_1].[dbo].[CRM_Member] cm  on ft.CardId=cm.ExternalMemberKey
  	 left join   report_data.[dbo].[v_get_reg_compAndStore]   s   on s.BuyingUnitInternalKey=cm.BuyingUnitInternalKey
	 and   s.MatrixMemberId=@MatrixMemberId  --首次注册油站
  left join [report_data].[dbo].store_gs  store on ftc.storeid=store.Storeid
   and store.MatrixMemberId=@MatrixMemberId 
   where   
   fth.CreatedDate>=convert(date,@createdDate,120)   and  fth.CreatedDate<convert(date,@createDateNextday,120)   
 and  s.compid is not null
    and  ftc.RetailerId=@RetailerId 
    order by fth.CreatedDate';
 set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_pre);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
		set @sql_text = replace(@sql_text,'@RetailerId', ''''+@RetailerId+'''');
 
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
	   set @sql_text = replace(@sql_text,'@CreatedDate',''''+@CreatedDate+'''');
	   set @sql_text = replace(@sql_text,'@createDateNextday',''''+@createDateNextday+'''');

	select  @sql_text
	exec(@sql_text);
	set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_cur);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
	set @sql_text = replace(@sql_text,'@RetailerId' ,''''+@RetailerId+'''');
--	set @sql_text = replace(@sql_text,'@CreatedDate_begin',''''+@CreatedDate_begin+'''');
--	set @sql_text = replace(@sql_text,'@CreatedDate_end',''''+@CreatedDate_end+'''');
--	set @sql_text = replace(@sql_text,'@business_end',''''+@business_end+'''');
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
   set @sql_text = replace(@sql_text,'@CreatedDate',''''+@CreatedDate+'''');
   set @sql_text = replace(@sql_text,'@createDateNextday',''''+@createDateNextday+'''');
   select @sql_text
	exec(@sql_text);
  
  ----替换积分分摊比例
  UPDATE  R2 SET  RegSharePoint=R2.redemption_point_q*(100-ISNULL(phpr.DOShare,0))*0.01 
           ,[RegShareAmount]=R2.redemption_point_je*(100-ISNULL(phpr.DOShare,0))*0.01 
      ,[RegRedeemAmount]=R2.redemption_point_amount*(100-ISNULL(phpr.DOShare,0))*0.01 
      
   FROM  DS_R2_redemption_point R2 INNER JOIN  RetailCode_MP RCM ON RCM.RetailerId=R2.RetailerId    
     LEFT JOIN [PromotionHeader_PR] phpr 	on phpr.PromotionHeaderId=R2.promotion_id  and  phpr.MatrixMemberId=R2.RetailerId

  update r2 set [TransSharePoint]=R2.redemption_point_q-RegSharePoint
      ,[TransShareAmount]=R2.redemption_point_je-RegShareAmount 
      ,[TransRedeemAmount]=R2.redemption_point_amount-RegRedeemAmount
   FROM  DS_R2_redemption_point R2 INNER JOIN  RetailCode_MP RCM ON RCM.RetailerId=R2.RetailerId    
     LEFT JOIN [PromotionHeader_PR] phpr 	on phpr.PromotionHeaderId=R2.promotion_id  and  phpr.MatrixMemberId=R2.RetailerId




  

--- R9-point detail list related to central adjustment 中央积分发放
--insert into adjust_center_point
truncate  table report_data.[dbo].[DS_r9_adjust] 
--where business_date >=@CreatedDate_begin   and business_date<=@business_end
 --       and   create_date>= @CreatedDate_begin
--		 and   create_date <@CreatedDate_end 
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
			 ,Retailerid
			 ,TaxCode
			 ,StoreType
			 ,itemId
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
  ,convert(varchar(10),cp.CreatedAt,120) 
  , @retailerID
   ,item.TaxCode
  ,s.storeType
  ,item.mainitemId
     from      Loyalty_Shell_1. [dbo].CRM_POSAccountsActivity  paa
    left join Loyalty_Shell_1.[dbo].[CRM_PointsUpdateReasonCodes] purc on paa.ReasonCode=purc.ReasonCode
	left join MP_Shell.dbo.GeneralDictionary gd on gd.EntryId=purc.ReasonDescription and gd.LanguageId=8
 
		 left join    [Loyalty_Shell_1].[dbo].[CRM_Member] cm  on paa.BuyingUnitInternalKey=cm.BuyingUnitInternalKey
	   left join   Loyalty_Shell_1. [dbo].[CRM_POSTran] cp on cp.POSTranInternalKey=paa.PosTranInternalKey
     left join  [Loyalty_Shell_1].dbo.[CRM_BuyingUnit] cbu on paa.BuyingUnitInternalKey=cbu.BuyingUnitInternalKey
	
    	 left join   report_data.[dbo].[v_get_reg_compAndStore]   s   on s.BuyingUnitInternalKey=cm.BuyingUnitInternalKey
		 and   s.MatrixMemberId=@MatrixMemberId  --首次注册油站
		left join  report_data..store_sku sk on   s.MatrixMemberId=sk.MatrixMemberId  and s.compid=sk.companyId   
		  left join  [report_data].[dbo].item_cat  item 	on item.MainItemId=sk.sku and item.MatrixMemberId=sk.MatrixMemberId
		   left join [report_data].[dbo].store_gs  store on s.StoreInternalKey=store.StoreInternalKey
 
 where
  ((posid=-66 ) or  (posid=-99 )) and paa.ReasonCode not in (11,17) -- and paa.ReasonCode<>7 
 --20201117   积分兑换异业积分调整（包含手工调整异业积分）reason code=11  
--20201117积分发放异业积分调整 reason code =17（预留） 


 -- and c1.compid is not null 
 and paa.AccountInternalKey=2 --使用100的账号 20170926
  and  cp.CreatedAt>=convert(date,@createdDate,120)   and  cp.CreatedAt<convert(date,@createDateNextday,120) 
     and s.MatrixMemberId=@MatrixMemberId   

 order by cp.PosDateTime';

 set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@TableDate_cur);
 
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
	 set @sql_text = replace(@sql_text,'@CreatedDate',''''+@CreatedDate+'''');
	 set @sql_text = replace(@sql_text,'@createDateNextday',''''+@createDateNextday+'''');
	  set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
	  	set @sql_text = replace(@sql_text,'@RetailerId' ,''''+@RetailerId+'''');
	select  @sql_text;
	exec(@sql_text);
 
	
delete from report_data.[dbo].[DS_r9_adjust]  where member_reg_comp_code is null or member_reg_comp is null 

  ---hos promotion  discount  
  
  truncate  table report_data.[dbo].[ds_h1_PromotionDiscount] ;
 set @sql_text_org=N'insert into  report_data.[dbo].ds_h1_PromotionDiscount (
           [RetailerId]      --1 jv  id
           ,[store_code]     -- 2交易油站代码
      ,[store_name]          --3交易油站名称
      ,[business_date]       --4营业日期
	   , ProcessDate         --5交易日期
	   ,processTime          --6交易时间
	  ,tranId               --7交易流水号 
      ,[PromotionId]         --8促销ID
      ,[PromotionDesc]       --9促销说明
      ,[PromtionType]        --10促销类型编号
      ,[PromtionTypeName]    --11促销类型名称
      ,[itemCode]            --12商品编号
      ,[quanlity]            --13数量
      ,[unit]                --14单位
      ,[SaleAmount]          --15零售金额
      ,[ReceiveAmount]       --16实收金额
      ,create_date             --17
	  ,RequiredCoupon
	  ,StationCoupon
	  ,StoreType
	    ,[COShare]
      ,[DOShare]
      ,[LegalCode]
      ,[LegalName]
      ,[item_cat_mid_cod]
      ,[item_cat_mid]
      ,[item_name]
      ,[taxCode]
	  ,DoBusinessCode	   )
select  ftc.RetailerId          --1 jv  id
  ,store.storeid              -- 2交易油站代码
 ,store.storename as store    --3交易油站名称
 ,convert(varchar(10),ftc.BusinessDate ,120) BusinessDate                   --4营业日期
  ,convert(varchar(10),fth.StartDateTime,120)  trandate                  --5交易日期
  ,CONVERT(varchar(100), fth.StartDateTime, 8)      trantime           --6交易时间,
  ,fth.TranId                              --7交易流水号
    ,ftprd.PromotionId                                            --8促销id
 ,phpr.PromotionHeaderDescription                      --9促销说明
  ,PromotionType                                     --10促销类型编号
  , null PromotiontypeName                              --11促销类型名称
  , ftprd.EntityId                               --12SKU 
 	 ,RewardedQty as qty                                    --13数量
	 ,null  as unit                                                --单位
	,fts.amount as amount                           --19应收金额
      ,fts.amount-isnull(ftprd.rewardValue,0) as netamount  --21实付金额
	  ,convert(varchar(10),fth.CreatedDate,120)
	  , isnull(phpr.RequiredCoupon,0) as RequiredCoupon
	  ,isnull( StationCoupon,0) StationCoupon
	  ,Store.Storetype
	  , ftprd.rewardValue*(100-phpr.DOShare)*0.01 as COShare
      ,ftprd.rewardValue*phpr.DOShare*0.01 as DOShare
      , store.compid as sal_com_id                                   --6公司代码
       ,store.comp as sal_com                             --公司名称
    
        ,item.midtypeCode                                --18 商品中类
      , item.midtype                                      --19 商品中类
        , item.FullName							        -- 21 商品 
		, item.TaxCode 
	     ,store.DoBusinessCode
	    from  [ATD_Shell].[dbo].[FO_TranCollection] ftc
	  inner  join  [ATD_Shell].dbo.FO_TranHeader201704 fth
on ftc.CollectionInternalKey=fth.CollectionInternalKey
 inner  join  [report_data].[dbo].store_gs store on store.storeid=ftc.storeid and  store.MatrixMemberId=@MatrixMemberId
 inner join  ( select  fts1.TicketInternalKey,fts1.ItemId,sum(fts1.Amount) as  amount,sum(fts1.qty) as qty  from  
	  [ATD_Shell].dbo.FO_TranSale201704 fts1   group  by  fts1.TicketInternalKey,fts1.ItemId ) fts
	on fts.TicketInternalKey=fth.TicketInternalKey
   left join ATD_Shell..FO_TranCard201704 (nolock)  ft on  ft.TicketInternalKey=fth.TicketInternalKey
		inner join ((select  distinct  TicketInternalKey, ftprd1.PromotionId ,    ftprd1.RewardValue   as RewardValue , entityid 
  ,RewardedQty
  from  [ATD_Shell].dbo.FO_TranPromotionRewardApportionment201704 ftprd1 where RewardMethodId=4) ) ftprd
	on ftprd.TicketInternalKey=fth.TicketInternalKey   and ftprd.EntityId=fts.ItemId 

  inner join  [report_data].[dbo].[PromotionHeader_PR] phpr 
	on phpr.PromotionHeaderId=ftprd.PromotionId  and  phpr.MatrixMemberId=@MatrixMemberId
	left join  [report_data].[dbo].item_cat  item 
	on item.MainItemId=ftprd.EntityId  and item.MatrixMemberId=@MatrixMemberId
		
		

  where     fth.CreatedDate>=convert(date,@createdDate,120)   and  fth.CreatedDate<convert(date,@createDateNextday,120)    -- and phpr.externalReferenceId is   null
   and     ftc.RetailerId='''+@retailerID+'''
    order by fth.CreatedDate';
	set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_pre);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
	set @sql_text = replace(@sql_text,'@RetailerId' ,''''+@RetailerId+'''');
		set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
    set @sql_text = replace(@sql_text,'@CreatedDate',''''+@CreatedDate+'''');
	set @sql_text = replace(@sql_text,'@createDateNextday',''''+@createDateNextday+'''');
	select  @sql_text
	exec(@sql_text);
	set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_cur);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
		set @sql_text = replace(@sql_text,'@RetailerId' ,''''+@RetailerId+'''');
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);

set @sql_text = replace(@sql_text,'@CreatedDate',''''+@CreatedDate+'''');
set @sql_text = replace(@sql_text,'@createDateNextday',''''+@createDateNextday+'''');
select @sql_text
	exec(@sql_text);
	 
	
------------discount------------------------




 ---E3 ds_E3_Discount
  
  truncate  table report_data.[dbo].ds_E3_Discount ;
 set @sql_text_org=N'
  select  distinct  TicketInternalKey, ftprd1.PromotionId ,    ftprd1.RewardValue   as RewardValue , entityid into  #ftprd1 
  from  [ATD_Shell].dbo.FO_TranPromotionRewardApportionment201704 ftprd1 where RewardMethodId=4 
 insert into  report_data.[dbo].ds_E3_Discount (
           [RetailerId]      --1 jv  id
           ,[store_code]     -- 2交易油站代码
      ,[store_name]          --3交易油站名称
      ,[business_date]       --4营业日期
	   , ProcessDate         --5交易日期
	   ,processTime          --6交易时间
	  ,tranId               --7交易流水号 
      ,[PromotionId]         --8促销ID
      ,[PromotionDesc]       --9促销说明
      ,[PromtionType]        --10促销类型编号
      ,[PromtionTypeName]    --11促销类型名称
      ,[itemCode]            --12商品编号
      ,[quanlity]            --13数量
      ,[unit]                --14单位
      ,[SaleAmount]          --15零售金额
      ,[ReceiveAmount]       --16实收金额
      ,create_date             --17
	  ,RequiredCoupon            --18
	  ,StationCoupon            --19
	  ,StoreType              --20
	 
      ,[LegalCode]   --21
      ,[LegalName]    --22
      ,[item_cat_mid_cod] --23
      ,[item_cat_mid]   --24
      ,[item_name]     --25
      ,[taxCode]      --26
	  
	  )
select  ftc.RetailerId          --1 jv  id
  ,store.storeid              -- 2交易油站代码
 ,store.storename as store    --3交易油站名称
 ,convert(varchar(10),ftc.BusinessDate ,120) BusinessDate                   --4营业日期
  ,convert(varchar(10),fth.StartDateTime,120)  trandate                  --5交易日期
  ,CONVERT(varchar(100), fth.StartDateTime, 8)      trantime           --6交易时间,
  ,fth.TranId                              --7交易流水号
    ,ftprd.PromotionId                                            --8促销id
 ,phpr.PromotionHeaderDescription                      --9促销说明
  ,PromotionType                                     --10促销类型编号
  , null PromotiontypeName                              --11促销类型名称
  , ftprd.EntityId                               --12SKU 
 	 ,fts.qty as qty                                    --13数量
	 ,null  as unit                                                --14单位
	,fts.amount as amount                           --15应收金额
      ,fts.amount-isnull(ftprd.rewardValue,0) as netamount  --16实付金额
	  ,convert(varchar(10),fth.CreatedDate,120)    --17
	  , isnull(phpr.RequiredCoupon,0) as RequiredCoupon --18
	  ,isnull( StationCoupon,0) StationCoupon        --19
	  ,Store.Storetype                          --20
	  , store.compid as sal_com_id                                   --21公司代码
       ,store.comp as sal_com                             --22公司名称
    
        ,item.midtypeCode                                --23 商品中类
      , item.midtype                                      --24 商品中类
        , item.firsttypeCode							        -- 25 商品 
		, item.TaxCode                            --26
	  
	    from  [ATD_Shell].[dbo].[FO_TranCollection] ftc
	  inner  join  [ATD_Shell].dbo.FO_TranHeader201704 fth
on ftc.CollectionInternalKey=fth.CollectionInternalKey
 inner  join  [report_data].[dbo].store_gs store on store.storeid=ftc.storeid and  store.MatrixMemberId=@MatrixMemberId
 inner join  ( select  fts1.TicketInternalKey,fts1.ItemId,sum(fts1.Amount) as  amount,sum(fts1.qty) as qty  from  
	  [ATD_Shell].dbo.FO_TranSale201704 fts1   group  by  fts1.TicketInternalKey,fts1.ItemId ) fts
	on fts.TicketInternalKey=fth.TicketInternalKey
   left join ATD_Shell..FO_TranCard201704 (nolock)  ft on  ft.TicketInternalKey=fth.TicketInternalKey
		inner join #ftprd1 ftprd
	on ftprd.TicketInternalKey=fth.TicketInternalKey   and ftprd.EntityId=fts.ItemId 

  inner join  [report_data].[dbo].[PromotionHeader_PR] phpr 
	on phpr.PromotionHeaderId=ftprd.PromotionId  and  phpr.MatrixMemberId=@MatrixMemberId
	left join  [report_data].[dbo].item_cat  item 
	on item.MainItemId=ftprd.EntityId  and item.MatrixMemberId=@MatrixMemberId
		
		

  where     fth.CreatedDate>=convert(date,@createdDate,120)   and  fth.CreatedDate<convert(date,@createDateNextday,120)    -- and phpr.externalReferenceId is   null
   and     ftc.RetailerId='''+@retailerID+'''
    order by fth.CreatedDate';
	set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_pre);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
	set @sql_text = replace(@sql_text,'@RetailerId' ,''''+@RetailerId+'''');
		set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
    set @sql_text = replace(@sql_text,'@CreatedDate',''''+@CreatedDate+'''');
	set @sql_text = replace(@sql_text,'@createDateNextday',''''+@createDateNextday+'''');
	select  @sql_text
	if OBJECT_ID('tempdb..#ftprd1') is not null 
  drop  table #ftprd1
	exec(@sql_text);
	set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_cur);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
		set @sql_text = replace(@sql_text,'@RetailerId' ,''''+@RetailerId+'''');
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);

set @sql_text = replace(@sql_text,'@CreatedDate',''''+@CreatedDate+'''');
set @sql_text = replace(@sql_text,'@createDateNextday',''''+@createDateNextday+'''');
select @sql_text
if OBJECT_ID('tempdb..#ftprd1') is not null 
  drop  table #ftprd1
	exec(@sql_text);
	 
	
------------discount------------------------


   end;










GO
