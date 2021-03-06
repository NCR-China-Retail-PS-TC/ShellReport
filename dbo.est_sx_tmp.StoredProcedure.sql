USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[est_sx_tmp]    Script Date: 1/19/2022 9:01:17 AM ******/
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
-- =============================================
CREATE PROCEDURE [dbo].[est_sx_tmp]
	 @createDate varchar(10)='2017-03-01'   --yyyy-mm-dd
	
	AS
BEGIN
  set transaction isolation  level read uncommitted;
     declare  @businessDate varchar(10)= @createDate
	 , @RetailId varchar(10)='2'
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
		 select @MatrixMemberId=MatrixMemberId from  RetailCode_MP rcmp     where rcmp.RetailerId=@RetailId   ;   ----sx RetailerId   is 2
		  set @Cowhere='  where  StoreType<>'+''''+'DO'+''''+' OR StoreType  is null '
		  set @Dowhere=' where  StoreType='+''''+'DO'+'''' +' OR StoreType='+''''+'SDO'+''''

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
 select cp.ClubCardId          --1????

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
   left join  Loyalty_Shell_1. [dbo].[CRM_POSTran] (nolock) cp 
    on cp.TranId=fth.TranId and cp.PosDateTime=ftc.BusinessDate and cp.StoreInternalKey=store.StoreInternalKey
	  and  cp.MatrixMemberId=@MatrixMemberId and cp.PosId=ftc.TillId
	--inner join [ATD_Shell].dbo.FO_TranSale201704 fts
---	on fts.TicketInternalKey=fth.TicketInternalKey
		
   left join (select  distinct  TicketInternalKey, ftprd1.PromotionId ,ftprd1.RewardValue , entityid 
  from  report_data..FO_TranPromotionRewardApportionment2020041 (nolock) ftprd1 where   RewardMethodId=1 and RewardId=100) ftprd1
  on ftprd1.TicketInternalKey=fth.TicketInternalKey   --and ftprd1.EntityId=fts.ItemId 
    left join report_data.[dbo].[PromotionHeader_PR] phpr 
	on phpr.PromotionHeaderId=ftprd1.PromotionId and phpr.MatrixMemberId=@MatrixMemberId
	left join  [report_data].[dbo].item_cat  item    on item.MainItemId=ftprd1.EntityId   and item.MatrixMemberId=@MatrixMemberId
	left join    [Loyalty_Shell_1].[dbo].[CRM_Member] (nolock) cm  on cp.BuyingUnitInternalKey=cm.BuyingUnitInternalKey
	/* left join   report_data.dbo.CRM_MemberStoreAssign_shell cmsa 
	    on cm.MemberInternalKey=cmsa.MemberInternalKey and cmsa.StoreTypeId=2 and cmsa.MatrixMemberId=@MatrixMemberId
	left join 	[report_data].[dbo].store_gs    s on s.StoreInternalKey=cmsa.StoreInternalKey
        and  s.MatrixMemberId=@MatrixMemberId  */
		 left join   report_data.[dbo].[v_get_reg_compAndStore]   s   on s.BuyingUnitInternalKey=cm.BuyingUnitInternalKey --??????
and s.MatrixMemberId=@MatrixMemberId
  where   fth.CreatedDate>=convert(date,@createDate,120)   and  fth.CreatedDate<convert(date,@createdDateNextday,120)
  and   phpr.PromotionHeaderId is not null   
  --  and s.StoreType is not null 
   and ftc.retailerid=@RetailerId
   and s.compid    is not null 
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

   end;


GO
