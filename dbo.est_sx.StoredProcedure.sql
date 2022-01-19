USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[est_sx]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  StoredProcedure [dbo].[est]    Script Date: 2017/3/2 18:01:20 ******/

-- =============================================
-- Author:		<Author,,Name>
---exec  [est_sx] '2019-05-12'
----rewardmethodid  (1-MemberAccount,2-Voucher,3-Coupon,4-Discount,5-MOP,6-Target Message,8=Decrease Member Account)
--Reardmethodid was descripted in  stp_Upload_Insert_TranPromotionRewardApportionment  Create date: <Create Date,,>
-- Description:	<Description,,>

--2020-07-29    modify R9
--20200804  cr312  doco
--20201110 CR333–陕西Loyalty积分接口处理逻辑调整
-- =============================================
CREATE PROCEDURE [dbo].[est_sx]
	 @createDate varchar(10)='2017-03-01'   --yyyy-mm-dd
	
	AS
BEGIN
  set transaction isolation  level read uncommitted;
     declare  @businessDate varchar(10)= @createDate
	 , @RetailId varchar(10)
       declare  @business_end   varchar(10);
	   declare @createdDateNextday varchar(10)= dateadd( day,1,convert(date,@createdate,120))
	  	 set @business_end=@businessDate;
	   
	  
	 
	    declare   @table VARCHAR(max) ='promotion_list'
		  ,@Server VARCHAR(max)   ='Loyalty_Shell_1.dbo.'
		  ,@FilePath NVARCHAR(400)=  'C:\Retalix\HQ\uploadfile_host\a\'  
		  ,@DOFilePath nvarchar(400)
		  ,@Expoprtfilename nvarchar(300)
		  ,@bal float =50.00 --per 50  point  for 1 rmb   201801102
		  ,@MatrixMemberId int
		  ,@Cowhere nvarchar(400)
		  ,@Dowhere nvarchar(400)
		  ,@TableWhere nvarchar(400)
		  ,@NoExistSKU varchar(400)
		   	 select @MatrixMemberId=MatrixMemberId,@RetailId=RetailerId
		  from  RetailCode_MP rcmp     where rcmp.RetailValue='2'   ;   ----sx RetailerId   is 2	
		set  @Cowhere= ' where ( StoreType='''+'COCO'+'''' +' OR isnull(StoreType,'''')='''')';
		  set @Dowhere=' where not   (StoreType='''+'COCO'+'''' +' OR isnull(StoreType,'''')='''')';

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

	select @FilePath=erc.ExtractLocalPath,@DOFilePath=erc.DOExtractLocalPath  from extractReportConfig erc where erc.MatrixMemberId=@MatrixMemberId
	
	print @filepath;
	set @TableDate_cur=SUBSTRING(REPLACE(@createDate,'-',''),1,6) --????
	set @TableDate_pre=SUBSTRING(REPLACE(convert( varchar,dateadd(month,-1,@createDate),120),'-',''),1,6) --???? ??????

		
	
	  ---查找未下发商品
	  exec FindLoyaltyNoExistSKU  @MatrixMemberId,@createDate
      set  @table='R_LoyaltyNoExistSKU';
      set  @Expoprtfilename=@filepath+@table+'\'+@table+@createDate+'.csv';
	  set  @NoExistSKU = ' where MatrixMemberId = ' + convert(varchar,@MatrixMemberId)
      exec  report_data.[dbo].est_export_cvs @table,@Server,@Expoprtfilename,@NoExistSKU;	
			      
			      
--R1-????? -- ??????:???????
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
		   ,create_date                 --22
		   ,StoreType                   --23
      
	)			
 select fc.CardId           --1????

,s.compid    compid            --2.0
,s.comp      regcomp           --2??????
,s.storeid   storeid           --3.0??????     
,s.storename  regstore         --3????????
,convert(varchar(10),s.UpdatedDate,120)  --3.1????
,store.comp as sal_com                                  --6????
,store.compid as sal_com_id                             --6.1????


  ,store.storeid                 --4 ????
 ,store.storename as stor       -- 5????
 
 ,store.city   city                                          --7??
 , ftc.CashierId                         --8Cashier ID
 ,fth.TranId                              --9?????
 ,convert(varchar(10),ftc.BusinessDate ,120) BusinessDate                   --10???
 ,convert(varchar(10),fth.StartDateTime,120)  trandate                  --11????
 ,CONVERT(varchar(100), fth.StartDateTime, 8)      trantime           --12????,
 ,ftc.TillId                                                                --13POS ID
, item.firsttype                     --14????
 ,item.midtypeCode
 , item.midtype                                     --15????
   
 ,   fts.ItemId                               --16SKU
  ,  item.FullName                        --17??
	--,fts.Price,                               --18
	,fts.Qty as qty ,                                  --18??
	fts.amount as amount ,                           --19????
     isnull(ftprd.rewardValue,0)  rewardValue              --20????
	 ,fts.amount-isnull(ftprd.rewardValue,0) as netamount  --21????
	 ,convert(varchar(10),fth.CreatedDate,120)
	 ,store.StoreType
	
     from    [ATD_Shell].[dbo].[FO_TranCollection](nolock) ftc
		
	 		  inner  join   [ATD_Shell].dbo.FO_TranHeader201704(nolock) fth 
		 
on ftc.CollectionInternalKey=fth.CollectionInternalKey 
			left join ATD_Shell..FO_TranCard201704 fc on fth.TicketInternalKey=fc.TicketInternalKey    
		
 inner  join  [report_data].[dbo].store_gs store on store.storeid=ftc.storeid and  store.MatrixMemberId=@MatrixMemberId
  	inner join  ( select  fts1.TicketInternalKey,fts1.ItemId,sum(fts1.Amount) as  amount,sum(fts1.qty) as qty  from  
	  [ATD_Shell].dbo.FO_TranSale201704 fts1   group  by  fts1.TicketInternalKey,fts1.ItemId ) fts
	on fts.TicketInternalKey=fth.TicketInternalKey
		left join (select    TicketInternalKey,		    sum(ftprd1.RewardValue)    as RewardValue , entityid
		 
  from  [ATD_Shell].dbo.FO_TranPromotionRewardApportionment201704 (nolock) ftprd1 where RewardMethodId=4 
     group by  TicketInternalKey,entityid ) ftprd

	on ftprd.TicketInternalKey=fts.TicketInternalKey and ftprd.EntityId=fts.ItemId 
 	left join  [report_data].[dbo].item_cat  item 
	on item.MainItemId=fts.ItemId and item.MatrixMemberId=@MatrixMemberId  
	left join    [Loyalty_Shell_1].[dbo].[CRM_Member] cm  on cm.ExternalMemberKey=fc.CardId
  
	 left join   report_data.[dbo].[v_get_reg_compAndStore]   s   on s.BuyingUnitInternalKey=cm.BuyingUnitInternalKey
	  and  s.MatrixMemberId=@MatrixMemberId  --??????

  where 	 fth.CreatedDate>=convert(date,@createDate,120)   and  fth.CreatedDate<convert(date,@createdDateNextday,120) 
	 and ftc.retailerid=@RetailerId
    order by fth.CreatedDate';

	set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_pre);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
	set @sql_text = replace(@sql_text,'@createDate',''''+@createDate+'''');
	 	set @sql_text = replace(@sql_text,'@business_end',''''+@business_end+'''');
		set @sql_text = replace(@sql_text,'@businessDate',''''+@businessDate+'''');
			set @sql_text = replace(@sql_text,'@RetailerId',''''+@RetailId+'''');
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
	set @sql_text = replace(@sql_text,'@createdDateNextday',''''+@createdDateNextday+'''');
print  @sql_text
	exec(@sql_text);
	set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_cur);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
	set @sql_text = replace(@sql_text,'@createDate',''''+@createDate+'''');
 
	set @sql_text = replace(@sql_text,'@business_end',''''+@business_end+'''');
	set @sql_text = replace(@sql_text,'@businessDate',''''+@businessDate+'''');
		set @sql_text = replace(@sql_text,'@RetailerId',''''+@RetailId+'''');
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
	set @sql_text = replace(@sql_text,'@createdDateNextday',''''+@createdDateNextday+'''');
	select @sql_text
	exec(@sql_text);


	print @table
 set  @table='R1_tran';
set  @Expoprtfilename=@filepath+@table+'\'+@table+@createDate+'-'+@business_end+'.csv';
 
exec  report_data.[dbo].est_export_cvs @Table,@Server,@Expoprtfilename,@Cowhere;
	
set  @Expoprtfilename=@DOFilePath+@table+'\'+@table+@createDate+'-'+@business_end+'.csv';
 
exec  report_data.[dbo].est_export_cvs @Table,@Server,@Expoprtfilename,@DOwhere;

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
		   ,StoreType                   --28
		   ,DOShare                     --29
		   ,COShare                     --30
		   )
select  ft.CardId          --1????
,s.compid    compid            --2.0
,s.comp      regcomp           --2??????
,s.storeid   storeid           --3.0??????     
,s.storename  regstore         --3????????
,store.comp as sal_com                                  --6????
,store.compid as sal_com_id                             --6.1????
  ,store.storeid                 --4 ????
 ,store.storename as stor       -- 5????
 
 ,store.city   city                                          --7??
 , ftc.CashierId                         --8Cashier ID
 ,fth.TranId                              --9?????
 ,convert(varchar(10),ftc.BusinessDate ,120) BusinessDate                   --10???
 ,convert(varchar(10),fth.StartDateTime,120)  trandate                  --11????
 ,CONVERT(varchar(100), fth.StartDateTime, 8)      trantime           --12????,
 ,ftc.TillId                                                                --13POS ID
, item.firsttype                     --14????
,item.midtypeCode
 , item.midtype                                     --15????
   
 ,   ftprd.EntityId                               --16SKU
  ,  item.FullName                        --17??
 

    , isnull(ftprd.rewardValue,0)  rewardValue              --20????
	
	 ,ftprd.PromotionId                                            --24??id
	 ,phpr.ExternalGroupId --phpr.PromotionGroupId                                 --25???
	 ,substring(phpr.ExternalReferenceID,1,8)                             --26 ????id
	 ,convert(varchar(10),fth.CreatedDate,120)                  --27 ????

	,store.StoreType                                   --28
	,round(phpr.DOShare*isnull(ftprd.rewardValue,0)*0.01,2) as DOShare --29
	,isnull(ftprd.rewardValue,0)-round(phpr.DOShare*isnull(ftprd.rewardValue,0)*0.01,2) as COShare --30
 from   [ATD_Shell].[dbo].[FO_TranCollection]  (nolock) ftc 
	  inner  join [ATD_Shell].dbo.FO_TranHeader201704 (nolock) fth
on ftc.CollectionInternalKey=fth.CollectionInternalKey

 inner  join  [report_data].[dbo].store_gs store(nolock) on store.storeid=ftc.storeid and  store.MatrixMemberId=@MatrixMemberId
 inner join  ( select  fts1.TicketInternalKey,fts1.ItemId,sum(fts1.Amount) as  amount,sum(fts1.qty) as qty  from  
	  [ATD_Shell].dbo.FO_TranSale201704 (nolock)  fts1   group  by  fts1.TicketInternalKey,fts1.ItemId ) fts
	on fts.TicketInternalKey=fth.TicketInternalKey
	left join ATD_Shell..FO_TranCard201704 (nolock)  ft on  ft.TicketInternalKey=fth.TicketInternalKey
  	inner join (select  distinct  TicketInternalKey, ftprd1.PromotionId ,    ftprd1.RewardValue   as RewardValue , entityid 
  ,RewardedQty
  from  [ATD_Shell].dbo.FO_TranPromotionRewardApportionment201704 (nolock) ftprd1 where RewardMethodId=4 ) ftprd
	on ftprd.TicketInternalKey=fth.TicketInternalKey   and ftprd.EntityId=fts.ItemId 

  inner  join  [report_data].[dbo].[PromotionHeader_PR] phpr 
	on phpr.PromotionHeaderId=ftprd.PromotionId  and  phpr.MatrixMemberId=@MatrixMemberId
	left join  [report_data].[dbo].item_cat  (nolock) item 
	on item.MainItemId=ftprd.EntityId  and item.MatrixMemberId=@MatrixMemberId
	 left join    [Loyalty_Shell_1].[dbo].[CRM_Member](nolock) cm  on  ft.CardId=cm.ExternalMemberKey
	 left join   report_data.[dbo].[v_get_reg_compAndStore] (nolock)  s   on s.BuyingUnitInternalKey=cm.BuyingUnitInternalKey 
		and s.MatrixMemberId=@MatrixMemberId
	

  where     fth.CreatedDate>=convert(date,@createDate,120)   and  fth.CreatedDate<convert(date,@createdDateNextday,120)    -- and phpr.externalReferenceId is   null

    order by fth.CreatedDate';
	set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_pre);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
	set @sql_text = replace(@sql_text,'@createDate',''''+@createDate+'''');
 
	set @sql_text = replace(@sql_text,'@business_end',''''+@business_end+'''');
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
	set @sql_text = replace(@sql_text,'@businessDate',''''+@businessDate+'''');
	set @sql_text = replace(@sql_text,'@createdDateNextday',''''+@createdDateNextday+'''');
	exec(@sql_text);
	set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_cur);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
	set @sql_text = replace(@sql_text,'@createDate',''''+@createDate+'''');
 set @sql_text = replace(@sql_text,'@createdDateNextday',''''+@createdDateNextday+'''');
	set @sql_text = replace(@sql_text,'@business_end',''''+@business_end+'''');
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
	set @sql_text = replace(@sql_text,'@businessDate',''''+@businessDate+'''');
	select @sql_text
	exec(@sql_text);
	 
	set  @table='R1_1_tran_discount';
    print @table
set  @Expoprtfilename=@filepath+@table+'\'+@table+@createDate+'-'+@business_end+'.csv';
 
exec  report_data.[dbo].est_export_cvs @Table,@Server,@Expoprtfilename,@Cowhere;
	
set  @Expoprtfilename=@DOFilePath+@table+'\'+@table+@createDate+'-'+@business_end+'.csv';
 
exec  report_data.[dbo].est_export_cvs @Table,@Server,@Expoprtfilename,@DOwhere;

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
		   ,StoreType                   --28
		  
		   )
 select fc.CardId           --1会员号码

,s.compid    compid            --2.0
,s.comp      regcomp           --2??????
,s.storeid   storeid           --3.0??????     
,s.storename  regstore         --3????????
,store.comp as sal_com                                  --6????
,store.compid as sal_com_id                             --6.1????
  ,store.storeid                 --4 ????
 ,store.storename as stor       -- 5????
 
 ,store.city   city                                          --7??
 , ftc.CashierId                         --8Cashier ID
 ,fth.TranId                              --9?????
 ,convert(varchar(10),ftc.BusinessDate ,120) BusinessDate                   --10???
 ,convert(varchar(10),fth.StartDateTime,120)  trandate                  --11????
 ,CONVERT(varchar(100), fth.StartDateTime, 8)      trantime           --12????,
 ,ftc.TillId                                                                --13POS ID
, item.firsttype                     --14????
,item.midtypeCode
 , item.midtype                                     --15????
   
 ,   ftprd1.EntityId                              --16SKU
  ,  item.FullName                        --17??
	
	 ,ftprd1.RewardValue as RewardvaluePoint        --22????
	, round(ftprd1.RewardValue/@bal,2)   as reward_amount                            --23??????
	 ,ftprd1.PromotionId                                            --24??id
	 ,phpr.ExternalGroupId                                 --25???
	 
	 ,substring(phpr.ExternalReferenceID,1,8)                             --26 ????id
	 ,convert(varchar(10),fth.CreatedDate,120)                  --27 ????
,store.StoreType                                   --28
	
   from    [ATD_Shell].[dbo].[FO_TranCollection] (nolock) ftc
		  
			  inner  join  [ATD_Shell].dbo.FO_TranHeader201704  (nolock) fth
		 
on ftc.CollectionInternalKey=fth.CollectionInternalKey
 inner  join  [report_data].[dbo].store_gs (nolock) store on store.storeid=ftc.storeid and store.MatrixMemberId=@MatrixMemberId
left join ATD_Shell..FO_TranCard201704 fc on fth.TicketInternalKey=fc.TicketInternalKey  
	--inner join [ATD_Shell].dbo.FO_TranSale201704 fts
---	on fts.TicketInternalKey=fth.TicketInternalKey
		
   left join (select  distinct  TicketInternalKey, ftprd1.PromotionId ,ftprd1.RewardValue , entityid 
  from  [ATD_Shell].dbo.FO_TranPromotionRewardApportionment201704 (nolock) ftprd1 where   RewardMethodId=1 and RewardId=100) ftprd1
  on ftprd1.TicketInternalKey=fth.TicketInternalKey   --and ftprd1.EntityId=fts.ItemId 
    left join report_data.[dbo].[PromotionHeader_PR] phpr 
	on phpr.PromotionHeaderId=ftprd1.PromotionId and phpr.MatrixMemberId=@MatrixMemberId
	left join  [report_data].[dbo].item_cat  item    on item.MainItemId=ftprd1.EntityId   and item.MatrixMemberId=@MatrixMemberId
	left join    [Loyalty_Shell_1].[dbo].[CRM_Member] (nolock) cm  on cm.ExternalMemberKey=fc.CardId
	/* left join   report_data.dbo.CRM_MemberStoreAssign_shell cmsa 
	    on cm.MemberInternalKey=cmsa.MemberInternalKey and cmsa.StoreTypeId=2 and cmsa.MatrixMemberId=@MatrixMemberId
	left join 	[report_data].[dbo].store_gs    s on s.StoreInternalKey=cmsa.StoreInternalKey
        and  s.MatrixMemberId=@MatrixMemberId  */
		 left join   report_data.[dbo].[v_get_reg_compAndStore]   s   on s.BuyingUnitInternalKey=cm.BuyingUnitInternalKey --??????
and s.MatrixMemberId=@MatrixMemberId
  where   fth.CreatedDate>=convert(date,@createDate,120)   and  fth.CreatedDate<convert(date,@createdDateNextday,120)
  and   phpr.PromotionHeaderId is not null
  and  s.compid is not null   
  --  and s.StoreType is not null 
   and ftc.retailerid=@RetailerId
    order by fth.CreatedDate';
	set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_pre);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
	set @sql_text = replace(@sql_text,'@createDate',''''+@createDate+'''');
  
	set @sql_text = replace(@sql_text,'@business_end',''''+@business_end+'''');
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
		set @sql_text = replace(@sql_text,'@businessDate',''''+@businessDate+'''');
				set @sql_text = replace(@sql_text,'@RetailerId',''''+@RetailId+'''');
			set @sql_text = replace(@sql_text,'@createdDateNextday',''''+@createdDateNextday+'''');
	print @sql_text;
	exec(@sql_text);
	set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_cur);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
	set @sql_text = replace(@sql_text,'@createDate',''''+@createDate+'''');
 
	set @sql_text = replace(@sql_text,'@business_end',''''+@business_end+'''');
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
	set @sql_text = replace(@sql_text,'@businessDate',''''+@businessDate+'''');
			set @sql_text = replace(@sql_text,'@RetailerId',''''+@RetailId+'''');
		set @sql_text = replace(@sql_text,'@createdDateNextday',''''+@createdDateNextday+'''');
		select @sql_text
	exec(@sql_text);
	
	set  @table='R1_2_tran_reward';
set  @Expoprtfilename=@filepath+@table+'\'+@table+@createDate+'-'+@business_end+'.csv';
 
exec  report_data.[dbo].est_export_cvs @Table,@Server,@Expoprtfilename,@Cowhere;
	
set  @Expoprtfilename=@DOFilePath+@table+'\'+@table+@createDate+'-'+@business_end+'.csv';
 
exec  report_data.[dbo].est_export_cvs @Table,@Server,@Expoprtfilename,@DOwhere;
------------------------------------
 --R2-?????? 
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
		    , redemption_point_je            --24  ??????

           ,[redemption_point_amount]       --25
		   ,redem_ce                        --26??  
           ,[promotion_id]                  --27
           ,[promotion_group]               --28
		    ,promtion_ref                   --29
		   ,create_date                     --30
		   ,StoreType                   --31
				   )
select   ft.CardId,                                  --1????

 s.compid    compid                                      --2.0
,s.comp      regcomp                                     --3??????
,s.storeid   storeid                                     --4.0??????     
,s.storename  regstore                                   --5????????
,store.comp as sal_com                                   --6????
,store.compid as sal_com_id                             --7????
  ,store.storeid                                         --8 ????
 ,store.storename as stor                                -- 9????
 ,  store.city   as city,                                --10??
    ftc.CashierId ,                                      --11cashierid
	  fth.TranId  ,                                      --12?????
  convert(varchar(10), ftc.BusinessDate,120) businessDate,        --13???
   convert(varchar(10),ftc.createddate,120) trandate,             --14????
   convert(varchar(8),ftc.createddate,8)  trantime,               --15????
   ftc.TillId   posid   ,                                         --16 '
 set @sql_text_org=@sql_text_org+N' 
   item.firsttype,                               --17????
  item.midtypeCode,                                               --18 ????
 item.midtype,                                                    --19 ????
 ftprd.EntityId,                                                 --20
  item.FullName,							                     -- 21 ??  
 ftprd.RewardedQty,                                               --22??
case when ftprds.RewardValue=0 then ftpma.AdjustmentValue else 
    cast(ftprd.rewardValue/ftprds.RewardValue*ftpma.AdjustmentValue as  decimal(10,2))  end    Redemption_quantity,   --23                --19?????? 
      case when ftprds.RewardValue=0 then ftpma.AdjustmentValue/@bal else 
	     cast(  ftprd.rewardValue/ftprds.RewardValue*ftpma.AdjustmentValue/@bal  as   decimal(10,2)) end  as redemption_point_je , --24  ??????
 cast( ftprd.rewardValue as  decimal(10,2))  redemption ,             --25?????? 
-1*case  when  ftprds.RewardValue=0 then  -1*ftpma.AdjustmentValue/@bal else 
   cast(ftprd.rewardValue-ftprd.rewardValue/ftprds.RewardValue*ftpma.AdjustmentValue /@bal  as   decimal(10,2))
   end   as    redem_ce ,  -- 26??'
    set @sql_text_org=@sql_text_org+N' 
  	 ftprd.PromotionId,                                  --27
	left( phpr.ExternalGroupId,5)                             --28

	 ,substring(phpr.ExternalReferenceID,1,8)                          --29 ????id
	 ,convert(varchar(10),fth.CreatedDate,120)                 --30 ????;

	 ,store.StoreType                                   --31
	
 
     from [ATD_Shell].[dbo].[FO_TranCollection] ftc
    inner join   [report_data].[dbo].store_gs  store1 on store1.storeid=ftc.StoreId
    and store1.MatrixMemberId=4   
	
 	  inner join	   [ATD_Shell].dbo.FO_TranHeader201704    fth
    on fth.CollectionInternalKey=ftc.CollectionInternalKey 
		 left join  [ATD_Shell].[dbo].fo_Trancard201704   ft on ft.TicketInternalKey=fth.TicketInternalKey

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
	 left join    [Loyalty_Shell_1].[dbo].[CRM_Member] cm  on ft.CardId=cm.ExternalMemberKey
   left join   report_data.[dbo].[v_get_reg_compAndStore]   s   on s.BuyingUnitInternalKey=cm.BuyingUnitInternalKey --??????
 and s.MatrixMemberId=@MatrixMemberId  -- and cp.MatrixMemberId=store.MatrixMemberId
 left join [report_data].[dbo].store_gs  store on ftc.storeid=store.Storeid  and store.MatrixMemberId=@MatrixMemberId
    where      fth.CreatedDate>=convert(date,@createDate,120)   and  fth.CreatedDate<convert(date,@createdDateNextday,120)
     and ftc.retailerid=@RetailerId
	 and  s.compid is not null
 '

  set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_pre);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
set @sql_text = replace(@sql_text,'@createDate',''''+@createDate+'''');
	set @sql_text = replace(@sql_text,'@createdDateNextday',''''+@createdDateNextday+'''');
		set @sql_text = replace(@sql_text,'@businessDate',''''+@businessDate+'''');
				set @sql_text = replace(@sql_text,'@RetailerId',''''+@RetailId+'''');
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
			set @sql_text = replace(@sql_text,'@businessDate',''''+@businessDate+'''');
					set @sql_text = replace(@sql_text,'@RetailerId',''''+@RetailId+'''');
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
  select  @sql_text
	exec(@sql_text);
   set  @table='R2_redemption_point'
set  @Expoprtfilename=@filepath+@table+'\'+@table+@createDate+'-'+@business_end+'.csv';
 
exec  report_data.[dbo].est_export_cvs @Table,@Server,@Expoprtfilename,@Cowhere;
	
set  @Expoprtfilename=@DOFilePath+@table+'\'+@table+@createDate+'-'+@business_end+'.csv';
 
exec  report_data.[dbo].est_export_cvs @Table,@Server,@Expoprtfilename,@DOwhere;

  ---R7-????
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
		   ,StoreType             
		   )

select 
  fc.CardId                 --????
   ,s.storeid                           --????
      ,s.storename        --????
	,s.compid as gs1                       --????
	,s.comp
	, s.city                                --??
	,ftc.CashierId                         --  Cashier ID
	,fth.TranId                            --?????
	,  convert(varchar(10),ftc.BusinessDate ,120)                                       --???
	,ftc.TillId                            --POS ID
	,tender.TenderName        --????
	,ttender.Amount               --??,
	,convert(varchar(10),fth.CreatedDate,120) 
	,s.StoreType  
     from  [ATD_Shell].[dbo].[FO_TranCollection] ftc  
		   inner join [ATD_Shell].dbo.FO_TranHeader201704 fth 
on ftc.CollectionInternalKey=fth.CollectionInternalKey 
 left join ATD_Shell..FO_TranCard201704 fc on fc.TicketInternalKey=fth.TicketInternalKey
  left join    [ATD_Shell].[dbo].[FO_TranTender201704]  ttender    on fth.TicketInternalKey=ttender.TicketInternalKey
  left join [ATD_Shell].[dbo].[Tender_ALL] tender on ttender.StoreTenderId=tender.TenderId and tender.MatrixMemberId=@MatrixMemberId
inner join 	[report_data].[dbo].store_gs    s on s.storeid=ftc.StoreId

 and s.MatrixMemberId=@MatrixMemberId
where  fth.CreatedDate>=convert(date,@createDate,120)   and  fth.CreatedDate<convert(date,@createdDateNextday,120)
   and ftc.TranTypeId in (20,23) and ttender.TicketInternalKey is not null
   and s.MatrixMemberId=@MatrixMemberId
      and ftc.retailerid=@RetailerId
 order by fth.CreatedDate'

 set @sql_text=@sql_text_org;

	set @sql_text = replace(@sql_text,'201704',@tableDate_pre);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
	set @sql_text = replace(@sql_text,'@createDate',''''+@createDate+'''');
 	set @sql_text = replace(@sql_text,'@createdDateNextday',''''+@createdDateNextday+'''');
	set @sql_text = replace(@sql_text,'@business_end',''''+@business_end+'''');
	set @sql_text = replace(@sql_text,'@RetailerId',''''+@RetailId+'''');
	set @sql_text = replace(@sql_text,'@bal',@bal);
set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
		set @sql_text = replace(@sql_text,'@businessDate',''''+@businessDate+'''');

	exec(@sql_text);
	set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_cur);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
	set @sql_text = replace(@sql_text,'@createDate',''''+@createDate+'''');
 	set @sql_text = replace(@sql_text,'@createdDateNextday',''''+@createdDateNextday+'''');
	set @sql_text = replace(@sql_text,'@business_end',''''+@business_end+'''');
	set @sql_text = replace(@sql_text,'@RetailerId',''''+@RetailId+'''');
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
	set @sql_text = replace(@sql_text,'@businessDate',''''+@businessDate+'''');

	exec(@sql_text);
	--	print @sql_text;
 set  @table='r7_payment_tender';
set  @Expoprtfilename=@filepath+@table+'\'+@table+@createDate+'-'+@business_end+'.csv';
 
exec  report_data.[dbo].est_export_cvs @Table,@Server,@Expoprtfilename,@Cowhere;
	
set  @Expoprtfilename=@DOFilePath+@table+'\'+@table+@createDate+'-'+@business_end+'.csv';
 
exec  report_data.[dbo].est_export_cvs @Table,@Server,@Expoprtfilename,@DOwhere;
print @table

 

--- R9-point detail list related to central adjustment ??????
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
           ,StoreType
		   ,ReasonCode
		   )   --12??????

select  cm.externalmemberkey     --1????
,s.compid as regcomp                  --2??????
,s.storename regstore                       --3??????

,s.storeid                                   --4????
,paa.PosTranInternalKey                  --5?????
,convert(varchar(10),paa.PosDateTime,120)                           --6???
,cp.PosId                                         --7posid
 ,isnull(gd.Value,purc.ReasonDescription)               --8??????
 ,   paa.EarnValue-paa.RedeemValue  EarnValue  --9??????
 , 0 --redempton        ---10??????
 ,convert(varchar(10),paa.ExpirationDate,120)                       --11??????
-- ,round(paa.EarnValue /@bal,2)  as awarding_amount      --12??????
    ,s.StoreType  
	,paa.ReasonCode    --20201110  
     from      Loyalty_Shell_1. [dbo].CRM_POSAccountsActivity  paa
    left join Loyalty_Shell_1.[dbo].[CRM_PointsUpdateReasonCodes] purc on paa.ReasonCode=purc.ReasonCode
	left join MP_Shell.dbo.GeneralDictionary gd on gd.EntryId=purc.ReasonDescription and gd.LanguageId=8
 
		 left join    [Loyalty_Shell_1].[dbo].[CRM_Member] cm  on paa.BuyingUnitInternalKey=cm.BuyingUnitInternalKey
	/*  left join    report_data.dbo.CRM_MemberStoreAssign_shell cmsa 
	    on cm.MemberInternalKey=cmsa.MemberInternalKey and cmsa.StoreTypeId=2
		left join 	[report_data].[dbo].store_gs    s on s.StoreInternalKey=cmsa.StoreInternalKey */
		left join   report_data.[dbo].[v_get_reg_compAndStore]   s   on s.BuyingUnitInternalKey=cm.BuyingUnitInternalKey --??????
		and s.MatrixMemberId=@MatrixMemberId
   left join [report_data].[dbo].store_gs  store on s.StoreInternalKey=store.StoreInternalKey and store.MatrixMemberId=s.MatrixMemberId
   left join   Loyalty_Shell_1. [dbo].[CRM_POSTran] cp on cp.POSTranInternalKey=paa.PosTranInternalKey
 where
  (posid=-66 or  posid=-99)   -- and paa.ReasonCode<>7  ---??erp ???B2C????,R????.
   and paa.AccountInternalKey=2 
    and s.MatrixMemberId=@MatrixMemberId 
   and cp.CreatedAt>=convert(date,@createDate,120)   and  cp.CreatedAt<convert(date,@createdDateNextday,120)
 
 order by cp.PosDateTime';

 set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@TableDate_cur);
	set @sql_text = replace(@sql_text,'@createDate',''''+@createDate+'''');
		set @sql_text = replace(@sql_text,'@createdDateNextday',''''+@createdDateNextday+'''');
 set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
		set @sql_text = replace(@sql_text,'@businessDate',''''+@businessDate+'''');

select  @sql_text;
	exec(@sql_text);
	
 set  @table='r9_adjust';
 print @table;
set  @Expoprtfilename=@filepath+@table+'\'+@table+@createDate+'-'+@business_end+'.csv';
 
exec  report_data.[dbo].est_export_cvs @Table,@Server,@Expoprtfilename,@Cowhere;
	
set  @Expoprtfilename=@DOFilePath+@table+'\'+@table+@createDate+'-'+@business_end+'.csv';
 
exec  report_data.[dbo].est_export_cvs @Table,@Server,@Expoprtfilename,@DOwhere;

----R9_adjust_1 R9-1 为Reason code =11、17的数据  20201117
declare @r9Where nvarchar(100)
set @r9Where=@cowhere+' and ReasonCode in (11,17)'
set  @Expoprtfilename=@filepath+@table+'_1'+'\'+@table+'_1'+@createDate+'-'+@business_end+'.csv';
 
exec  report_data.[dbo].est_export_cvs @Table,@Server,@Expoprtfilename,@r9Where;
set @r9Where=@dowhere+' and ReasonCode in (11,17)'	
set  @Expoprtfilename=@DOFilePath+@table+'_1'+'\'+@table+'_1'+@createDate+'-'+@business_end+'.csv';
 
exec  report_data.[dbo].est_export_cvs @Table,@Server,@Expoprtfilename, @r9Where;
----
----R9_adjust_2   为排除Reason code =11、17的数据。
set @r9Where=@cowhere+' and ReasonCode not in (11,17)'
set  @Expoprtfilename=@filepath+@table+'_2'+'\'+@table+'_2'+@createDate+'-'+@business_end+'.csv';
 
exec  report_data.[dbo].est_export_cvs @Table,@Server,@Expoprtfilename, @r9Where;
set @r9Where=@dowhere+' and ReasonCode not  in (11,17)'	
set  @Expoprtfilename=@DOFilePath+@table+'_2'+'\'+@table+'_2'+@createDate+'-'+@business_end+'.csv';
 
exec  report_data.[dbo].est_export_cvs @Table,@Server,@Expoprtfilename, @r9Where;


  
 
--insert into .R10_1_member_list_top20
   delete report_data.dbo.R10_1_fraud_control;
set @sql_text_org=N'
INSERT INTO  report_data.[dbo].[R10_1_fraud_control]  
           ([row_num]             --1     ???
           ,[tran_date]           --2     ????
           ,[store_id]            --3      ???
           ,[store_name]          --4      ??
           ,[comp_name]          --5       ???
           ,[comp_id]            --6       ????
           ,[member_card_no]          --7       ????
           ,[petrol_amount]       --8      ????
           ,[diesel_oil_amount]   --9      ????
           ,[conven_goods_amount]  --10   ?????
           ,[total_amount])         --11  ???
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
 where ftprd.RewardMethodId=1  --and   convert(varchar(10),fth.CreatedDate,120)>=@createDate 
 -- and convert(varchar(10),fth.CreatedDate,120)<=@createDate_end and ftc.BusinessDate>=@createDate and ftc.BusinessDate<=@business_end
  and  ftc.BusinessDate=convert(date,@businessDate,120)  -- and ftc.storeid in (select storeid from  report_data.dbo.store_etl  st 
	                                   --          where st.businessCount=1 and st.businessDate=@businessDate)

 group by  ftc.BusinessDate,ftc.StoreId,store.storename,store.compID,store.comp,cm.ExternalMemberKey)a 
 where rownum<=20
  order by  StoreId, storename, compID, comp,rownum  '
     set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@TableDate_cur);
	set @sql_text = replace(@sql_text,'@createDate',''''+@createDate+'''');
 set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
	set @sql_text = replace(@sql_text,'@bal',@bal);
		set @sql_text = replace(@sql_text,'@business_end',''''+@business_end+'''');
		set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
	set @sql_text = replace(@sql_text,'@businessDate',''''+@businessDate+'''');

	print @sql_text;
	exec(@sql_text);
	
   set  @table='R10_1_fraud_control';
   print @table
set  @Expoprtfilename=@filepath+@table+'\'+@table+@createDate+'-'+@business_end+'.csv';
exec  report_data.[dbo].est_export_cvs @table,@Server,@Expoprtfilename;	

---------?????????5?------------------
  delete report_data.dbo.R10_2_top5_detail;
set @sql_text_org=N'
  with 
	cpt as ( select  *  from Loyalty_Shell_1..CRM_POSTran cpt
	 where cpt.PosDateTime>convert(datetime ,@businessDate,120)-7 and cpt.PosDateTime<=convert(datetime,@businessDate,120)
	  and IsTransactionVoid  =0 and MatrixMemberId=@MatrixMemberId  )
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
  inner join   cpt on cpaa.PosTranInternalKey=cpt.POSTranInternalKey   and AccountInternalKey=2  and cpaa.MatrixMemberId=cpt.MatrixMemberId
       group by cpt.StoreInternalKey , cpt.BuyingUnitInternalKey,cpt.MatrixMemberId  )  buyingUnit  where sequence<=5) buyingunit 
   
    inner join  cpt on buyingUnit.BuyingUnitInternalKey=cpt.BuyingUnitInternalKey and cpt.MatrixMemberId=buyingUnit.MatrixMemberId
	 inner join  Loyalty_Shell_1..CRM_POSAccountsActivity cpaa on  cpaa.PosTranInternalKey=cpt.POSTranInternalKey   and AccountInternalKey=2  
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


----------------------2018-09-18  ????????>10??????---
  delete report_data.dbo.R10_3_top10_TranFreq;
set @sql_text_org=N'
    with 
	cpt as ( select  *  from Loyalty_Shell_1..CRM_POSTran cpt
	 where cpt.PosDateTime>convert(datetime ,@businessDate,120)-7 and cpt.PosDateTime<=convert(datetime,@businessDate,120) and IsTransactionVoid  =0 and MatrixMemberId=@MatrixMemberId  )

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
  inner join   cpt on cpaa.PosTranInternalKey=cpt.POSTranInternalKey   and AccountInternalKey=2  and cpaa.MatrixMemberId=cpt.MatrixMemberId
       group by  cpt.BuyingUnitInternalKey,cpt.MatrixMemberId  having count(1)>10)  buyingUnit
	 inner join  cpt on buyingUnit.BuyingUnitInternalKey=cpt.BuyingUnitInternalKey and cpt.MatrixMemberId=buyingUnit.MatrixMemberId
	 inner join  Loyalty_Shell_1..CRM_POSAccountsActivity cpaa on  cpaa.PosTranInternalKey=cpt.POSTranInternalKey   and AccountInternalKey=2  
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
		   ,StoreType
		   )
  select  distinct substring(phpr.ExternalReferenceID,1,8)       ---1????ID
,phpr.ExternalGroupId   --   20170809             --2???ID
, PromotionGroupName   --3
,PromotionHeaderDescription      --4???? 
,	phpr.PromotionHeaderStartDate --5??????
,phpr.PromotionHeaderEndDate        --6??????
,case when phpr.SuspendStatus=1 then N'''+N'正常'+'''
ELSE N'''+N'挂起'+''' end  status ,
phpr.PromotionHeaderId,
UpdatedDate                         --???? 
,store.StoreType  
   from    [ATD_Shell].dbo.FO_TranHeader201704  fth  
		 inner  join [ATD_Shell].[dbo].[FO_TranCollection] ftc
on ftc.CollectionInternalKey=fth.CollectionInternalKey and  ftc.RetailerId='+''''+@RetailId+'''' +'
 inner  join  [report_data].[dbo].store_gs store on store.storeid=ftc.storeid and store.MatrixMemberId=@MatrixMemberId
  left join   
   [ATD_Shell].dbo.FO_TranPromotionRewardApportionment201704 ftprd1   
  on ftprd1.TicketInternalKey=fth.TicketInternalKey  and  RewardMethodId in (1,4,5)    
   inner join [report_data].[dbo].[PromotionHeader_PR] phpr 
	on phpr.PromotionHeaderId=ftprd1.PromotionId	and phpr.MatrixMemberId=@MatrixMemberId
   where  convert(varchar(10),fth.CreatedDate,120)>=@createDate
 order by phpr.ExternalGroupId,substring(phpr.ExternalReferenceID,1,8)    DESC  ';
  set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@TableDate_cur);
	set @sql_text = replace(@sql_text,'@createDate',''''+@createDate+'''');
 set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
		set @sql_text = replace(@sql_text,'@business_end',''''+@business_end+'''');
	set @sql_text = replace(@sql_text,'@businessDate',''''+@businessDate+'''');

	exec(@sql_text);
	
   set  @table='R13_promotion_list';
   print  @table;
set  @Expoprtfilename=@filepath+@table+'\'+@table+@createDate+'-'+@business_end+'.csv';
--exec  report_data.[dbo].est_export_cvs @table,@Server,@Expoprtfilename;	


--set  @Expoprtfilename=@filepath+@table+'\'+@table+@createDate+'-'+@business_end+'.csv';
 
exec  report_data.[dbo].est_export_cvs @Table,@Server,@Expoprtfilename,@Cowhere;
	
set  @Expoprtfilename=@DOFilePath+@table+'\'+@table+@createDate+'-'+@business_end+'.csv';
 
exec  report_data.[dbo].est_export_cvs @Table,@Server,@Expoprtfilename,@DOwhere;


	--Reconciliation
	delete report_data..ReconciliationR2ERP 
	where RetailerId = @RetailId 
	and DataType in ('R1_2','R9','R2','R1_1_H1')
	and CreatedAt = @CreateDate;

	insert into report_data..ReconciliationR2ERP
	(	RetailerId,
		DataType,
		CreatedAt,
		BusinessDate,
		Point,
		StoreType
	)
	select @RetailId,'R1_2',r.create_date,r.business_date,sum(r.reward_point),r.StoreType
	from r1_2_tran_reward r
	where r.member_reg_comp_code is not null
	group by r.create_date,r.business_date,r.StoreType
	union
	select @RetailId,'R9',@CreateDate,r.business_date,sum(r.number_awarding),r.StoreType
	from r9_adjust r
	where r.reason_adjust not in (N'B2C积分补录',N'老会员积分迁移')
	group by r.business_date,r.StoreType
	union
	select @RetailId,'R2',r.create_date,r.business_date,sum(r.redemption_point_q),r.StoreType
	from R2_redemption_point r
	where r.member_reg_comp_code is not null
	--and r.posid <> 99
	group by r.create_date,r.business_date,r.StoreType
	union
	select @RetailId,'R1_1_H1',r.create_date,r.business_date,sum(r.discount_amount),r.StoreType
	from R1_1_tran_discount r
	where --r.member_reg_comp_code is not null
	 --r.promtion_ref is null
	 r.StoreType <> 'DO' or r.StoreType is null
	group by r.create_date,r.business_date,r.StoreType


   end;


GO
