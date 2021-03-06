USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[est_cross]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
	-- exec [est_cross] '2020-05-01',2


	CREATE  PROCEDURE [dbo].[est_cross]
	 @createDate_begin varchar(10)='2017-03-01'   --yyyy-mm-dd
	,@retailid varchar(10)
		
	AS
BEGIN
   set transaction isolation  level read uncommitted;
	   declare  @CreateDate varchar(10)= @createDate_begin
     		 declare @createdDateNextday varchar(10)= dateadd( MONTH,1,convert(date,@createdate,120))
  , @MatrixMemberId int=1
  
	    declare  @business_end   varchar(10);
		
		set @business_end=@CreateDate;
	    declare   @table VARCHAR(max) ='promotion_list'
		  ,@Server VARCHAR(max)   ='Loyalty_Shell_1.dbo.'
		  ,@FilePath NVARCHAR(400)=  'C:\Retalix\HQ\uploadfile_host\a\'   
		  ,@Expoprtfilename nvarchar(300)
		  ,@bal int =50; --per 50  point  for 1 rmb   2018.11.05
    declare @tableDate_cur varchar(6) ,@tableDate_pre varchar(6) 
	,@atd_Server nvarchar(100) 		
	,@ServerHost nvarchar(100) 
	,@loyalty_server varchar(100) 
	,@sql_text  nvarchar(max)
	,@sql_text_org nvarchar(max)
	,@DOFilePath nvarchar(400)
    ,@Cowhere nvarchar(400)
    ,@Dowhere nvarchar(400)
   ,@TableWhere nvarchar(400)
	select @atd_Server=c.paraValue0   from dbo.param_config c  where c.paraName='atd_Server';
	select @ServerHost=c.paraValue0   from dbo.param_config c  where c.paraName='ServerHost';
	select @loyalty_server=c.paraValue0   from dbo.param_config c  where c.paraName='loyalty_server';
		 select @MatrixMemberId=MatrixMemberId from  RetailCode_MP rcmp     where rcmp.RetailerId=@RetailId   ;   ----sx RetailerId   is 2

	
	select @FilePath=erc.ExtractLocalPath  from extractReportConfig erc where erc.MatrixMemberId=@MatrixMemberId
	     set @Cowhere='  where  StoreType<>'+''''+'DO'+''''+' OR StoreType  is null '
		  set @Dowhere=' where  StoreType='+''''+'DO'+''''
	 
	set @TableDate_cur=SUBSTRING(REPLACE(@createDate_begin,'-',''),1,6) --????
	set @TableDate_pre=SUBSTRING(REPLACE(convert( varchar,dateadd(month,-1,@createDate_begin),120),'-',''),1,6) --???? ??????
	select @FilePath=erc.ExtractLocalPath,@DOFilePath=erc.DOExtractLocalPath  from extractReportConfig erc where erc.MatrixMemberId=@MatrixMemberId

		
 --delete report_data.[dbo].r1_tran_cross ;
 set @sql_text_org=N' insert into  report_data.[dbo].[r1_tran_cross] (
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
         
           ,[transaction_no]			--9
           ,[business_date]				--10
           ,[due_amount]				--19
         
      
	)			
 select cp.ClubCardId          --1????

,s.compid    compid            --2.0
,s.comp      regcomp           --2??????
,s.storeid   storeid           --3.0??????     
,s.storename  regstore         --3????????
,convert(varchar(10),s.UpdatedDate,120)  --3.1????
,store.comp as sal_com                                  --6????
,store.compid as sal_com_id                             --6.1????
  ,store.storeid                 --4 ????
 ,store.storename as stor       -- 5????
 
 
 ,fth.TranId                              --9?????
 ,convert(varchar(10),ftc.BusinessDate ,120) BusinessDate                   --10???
 	,fts.amount as amount                            --19????
   
	
     from  [ATD_Shell].[dbo].[FO_TranCollection] ftc 
		 
	 	 inner join report_data..RetailCode_MP rc on ftc.RetailerId=rc.RetailerId	 
		  
		  inner  join  [ATD_Shell].dbo.FO_TranHeader201704 fth  (nolock)
		 
on ftc.CollectionInternalKey=fth.CollectionInternalKey
 inner  join  [report_data].[dbo].store_gs store on store.storeid=ftc.storeid and  store.MatrixMemberId=rc.MatrixMemberId
   inner join  Loyalty_Shell_1. [dbo].[CRM_POSTran] cp (nolock)
    on cp.TranId=fth.TranId and cp.PosDateTime=ftc.BusinessDate and cp.StoreInternalKey=store.StoreInternalKey
	   and cp.MatrixMemberId=rc.MatrixMemberId and cp.PosId=ftc.TillId
	inner join ATD_Shell.dbo.FO_TranSale201704 fts
	on fts.TicketInternalKey=fth.TicketInternalKey
 		inner join    [Loyalty_Shell_1].[dbo].[CRM_Member] cm  on cp.BuyingUnitInternalKey=cm.BuyingUnitInternalKey
   inner  join   report_data.[dbo].[v_get_reg_compAndStore]   s   on s.BuyingUnitInternalKey=cm.BuyingUnitInternalKey
    
  where 
  	fth.CreatedDate>=convert(date,@createDate,120)   and  fth.CreatedDate<convert(date,@CreatedDateNextday,120)
	-- and ftc.retailerid=@RetailerId  
	  and  s.MatrixMemberId<>rc.MatrixMemberId --??????
	    ';
	
	set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_pre);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
	set @sql_text = replace(@sql_text,'@CreateDate',''''+@CreateDate+'''');
	set @sql_text = replace(@sql_text,'@CreatedDateNextday',''''+@CreatedDateNextday+'''');
	set @sql_text = replace(@sql_text,'@RetailerId',''''+@RetailId+'''');
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);

	exec(@sql_text);
	set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_cur);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
	
	set @sql_text = replace(@sql_text,'@CreateDate',''''+@CreateDate+'''');
	set @sql_text = replace(@sql_text,'@CreatedDateNextday',''''+@CreatedDateNextday+'''');
	set @sql_text = replace(@sql_text,'@RetailerId',''''+@RetailId+'''');
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
	select @sql_text
	exec(@sql_text);
	
	print @table
 set  @table='R1_tran_cross';
set  @Expoprtfilename=@filepath+@table+'\'+@table+@createDate+'-'+@business_end+'.csv';
 
exec  report_data.[dbo].est_export_cvs @Table,@Server,@Expoprtfilename,@Cowhere;
	
set  @Expoprtfilename=@DOFilePath+@table+'\'+@table+@createDate+'-'+@business_end+'.csv';
 
exec  report_data.[dbo].est_export_cvs @Table,@Server,@Expoprtfilename,@DOwhere;

 
 


--delete report_data.[dbo].r1_2_tran_reward_cross ;
set @sql_text_org=N'insert into  report_data.[dbo].[r1_2_tran_reward_cross] (
            [member_card_no]              --1
           , member_reg_comp_code          --2.0
           , member_reg_comp				  --2
           , member_reg_store_code         --3.0
           , member_reg_store              --3
		   
           , legal_code                    --6
           , legal_name                    --6.1
           , store_code                    --4 
           , store_name                    --5
           ,[transaction_no]			--9
           ,[business_date]				--10
           
           ,[reward_point]				--22
           ,[reward_amount]				--23
         
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
 

 ,fth.TranId                              --9交易流水号
 ,convert(varchar(10),ftc.BusinessDate ,120) BusinessDate                   --10营业日
 	 ,ftprd1.RewardValue as RewardvaluePoint        --22获得积分
	, round(ftprd1.RewardValue/@bal,2)   as reward_amount                            --23积分发放金额
	

   from    [ATD_Shell].[dbo].[FO_TranCollection] ftc
		   inner join report_data..RetailCode_MP rc on ftc.RetailerId=rc.RetailerId	 
	
			  inner  join [ATD_Shell].dbo.FO_TranHeader201704 fth
		 
on ftc.CollectionInternalKey=fth.CollectionInternalKey
 inner  join  [report_data].[dbo].store_gs store on store.storeid=ftc.storeid and store.MatrixMemberId=rc.MatrixMemberId
   left join  Loyalty_Shell_1. [dbo].[CRM_POSTran] cp 
    on cp.TranId=fth.TranId and cp.PosDateTime=ftc.BusinessDate and cp.StoreInternalKey=store.StoreInternalKey
	  and  cp.MatrixMemberId=rc.MatrixMemberId and cp.PosId=ftc.TillId
	
   left join (select  distinct  TicketInternalKey, ftprd1.PromotionId ,ftprd1.RewardValue , entityid 
  from  [ATD_Shell].dbo.FO_TranPromotionRewardApportionment201704 ftprd1 where   RewardMethodId=1 and RewardId=100) ftprd1
  on ftprd1.TicketInternalKey=fth.TicketInternalKey   --and ftprd1.EntityId=fts.ItemId 
  	left join    [Loyalty_Shell_1].[dbo].[CRM_Member] cm  on cp.BuyingUnitInternalKey=cm.BuyingUnitInternalKey
	
		 left join   report_data.[dbo].[v_get_reg_compAndStore]   s   on s.BuyingUnitInternalKey=cm.BuyingUnitInternalKey --首次注册油站

  where fth.CreatedDate>=convert(date,@createDate,120)   and  fth.CreatedDate<convert(date,@createdDateNextday,120) 
     and s.MatrixMemberId<>rc.MatrixMemberId
--  and  ftc.RetailerId=@retailId 
    ';
	set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_pre);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
	set @sql_text = replace(@sql_text,'@createDate',''''+@createDate+'''');
  set @sql_text = replace(@sql_text,'@createdDateNextday',''''+@createdDateNextday+'''');
	set @sql_text = replace(@sql_text,'@business_end',''''+@business_end+'''');
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
	
		set @sql_text = replace(@sql_text,'@retailId',''''+@RetailId+'''');
	print @sql_text;
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

	set @sql_text = replace(@sql_text,'@retailId',''''+@RetailId+'''');
  select @sql_text 
	exec(@sql_text);
	
	set  @table='R1_2_tran_reward_cross';
      set  @Expoprtfilename=@filepath+@table+'\'+@table+@createDate+'-'+@business_end+'.csv';
 
     exec  report_data.[dbo].est_export_cvs @Table,@Server,@Expoprtfilename,@Cowhere;
	
     set  @Expoprtfilename=@DOFilePath+@table+'\'+@table+@createDate+'-'+@business_end+'.csv';
 
     exec  report_data.[dbo].est_export_cvs @Table,@Server,@Expoprtfilename,@DOwhere;

------------------------------------
 --R2-油站积分兑换 
 -- set @redemption_point_sql=

 delete  report_data. [dbo].R2_redemption_point_cross;

set  @sql_text_org=N'insert into report_data. [dbo].R2_redemption_point_cross
          ([member_card_no]                   --1
          , member_reg_comp_code              --2
          ,  member_reg_comp				  --3
          ,  member_reg_store_code            --4
          ,  member_reg_store			      --5
          ,  legal_code                       --6
          ,  legal_name                       --7
          ,  store_code                       --8 
          ,  store_name                       --9

           ,[transaction_no]                 --12
           ,[business_date]                  --13
            ,[redemption_point_q]             --23
		    , redemption_point_je            --24  积分折算金额

           ,[redemption_point_amount]       --25
		   ,redem_ce                        --26差额  
          
		   )
select    ft.CardId,                                    --1会员号码

 s.compid    compid                                      --2.0
,s.comp      regcomp                                     --3会员注册公司
,s.storeid   storeid                                     --4.0会员注册油站     
,s.storename  regstore                                   --5会员注册默认油站
,store.comp as sal_com                                   --6公司代码
,store.compid as sal_com_id                             --7公司代码
  ,store.storeid                                         --8 油站代码
 ,store.storename as stor                                -- 9油站名称

	,  fth.TranId                                        --12交易流水号
 , convert(varchar(10), ftc.BusinessDate,120) businessDate        --13营业日
  '
 set @sql_text_org=@sql_text_org+N' 
                                               
,case when ftprds.RewardValue=0 then ftpma.AdjustmentValue else 
    cast(ftprd.rewardValue/ftprds.RewardValue*ftpma.AdjustmentValue as  decimal(10,2))  end    Redemption_quantity,   --23                --19积分兑换数量 
      case when ftprds.RewardValue=0 then ftpma.AdjustmentValue/@bal else 
	     cast(  ftprd.rewardValue/ftprds.RewardValue*ftpma.AdjustmentValue/@bal  as   decimal(10,2)) end  as redemption_point_je , --24  积分折算金额
 cast( ftprd.rewardValue as  decimal(10,2))  redemption ,             --25积分抵扣金额 
-1*case  when  ftprds.RewardValue=0 then  -1*ftpma.AdjustmentValue/@bal else 
   cast(ftprd.rewardValue-ftprd.rewardValue/ftprds.RewardValue*ftpma.AdjustmentValue /@bal  as   decimal(10,2))
   end   as    redem_ce   -- 26差额'
    set @sql_text_org=@sql_text_org+N' 
  	
 
     from  [ATD_Shell].[dbo].[FO_TranCollection] ftc  --Loyalty_Shell_1. [dbo].[CRM_POSTran] cp
	  inner join report_data..RetailCode_MP rc on ftc.RetailerId=rc.RetailerId	 
	
	 inner  join [ATD_Shell].dbo.FO_TranHeader201704    fth  on fth.CollectionInternalKey=ftc.CollectionInternalKey
     inner join   [report_data].[dbo].store_gs  store1 on store1.storeid=ftc.StoreId  and store1.MatrixMemberId=rc.MatrixMemberId
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
  
  set @sql_text_org=@sql_text_org+N' 
  		 left join    [Loyalty_Shell_1].[dbo].[CRM_Member] cm  on  ft.CardId=cm.ExternalMemberKey
   left join   report_data.[dbo].[v_get_reg_compAndStore]   s   on s.BuyingUnitInternalKey=cm.BuyingUnitInternalKey --首次注册油站
  -- and cp.MatrixMemberId=store.MatrixMemberId
 left join [report_data].[dbo].store_gs  store on ftc.storeid=store.Storeid
   and store.MatrixMemberId=rc.MatrixMemberId  and rc.MatrixMemberId=store.MatrixMemberId 
    where    fth.CreatedDate>=convert(date,@createDate,120)   and  fth.CreatedDate<convert(date,@createdDateNextday,120) 
  --and  ftc.RetailerId=@retailId 
  and s.MatrixMemberId<>rc.MatrixMemberId
  '

  set @sql_text=@sql_text_org;
	set @sql_text = replace(@sql_text,'201704',@tableDate_pre);
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
set @sql_text = replace(@sql_text,'@createDate',''''+@createDate+'''');
set @sql_text = replace(@sql_text,'@createdDateNextday',''''+@createdDateNextday+'''');

	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
	set @sql_text = replace(@sql_text,'@retailId',''''+@RetailId+'''');
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
set @sql_text = replace(@sql_text,'@retailId',''''+@RetailId+'''');
select 	@sql_text
	exec(@sql_text);
   set  @table='R2_redemption_point_cross'
     set  @Expoprtfilename=@filepath+@table+'\'+@table+@createDate+'-'+@business_end+'.csv';
 
     exec  report_data.[dbo].est_export_cvs @Table,@Server,@Expoprtfilename,@Cowhere;
	
     set  @Expoprtfilename=@DOFilePath+@table+'\'+@table+@createDate+'-'+@business_end+'.csv';
 
     exec  report_data.[dbo].est_export_cvs @Table,@Server,@Expoprtfilename,@DOwhere;





end
GO
