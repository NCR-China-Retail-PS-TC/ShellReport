USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[member_point_detail_0706]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE  [dbo].[member_point_detail_0706]
	@business_date varchar(10)	
	
AS
BEGIN
declare  @createdate_end1 varchar(10);
declare @PosTranInternalKey  [int] ,
    	@AccountInternalKey [int] ,
		@BuyingUnitInternalKey [int] ,
		@MatrixMemberId [smallint] ,
		@PosDateTime [smalldatetime],
		@ProcessDate [smalldatetime] ,
		@EarnValue [money] ,
		@RedeemValue [money],
		@InitialValue [money],
		@ExpirationDate [smalldatetime] ,
		@ReasonCode [tinyint] ,
		@Remarks [nvarchar](256) ,
		@SourcePosTranInternalKey [int],
		@balance float, 
		@pos_key int
	--	@business_date varchar(10)	;
		set @balance=0;

	 
	 --  set @business_date=convert(varchar(10),dateadd(day,-1,getdate()),120);
	 
	    declare   @table VARCHAR(max) ='promotion_list'
		  ,@Server VARCHAR(max)   ='Loyalty_Shell_1.dbo.'
		  ,@FilePath NVARCHAR(100)=  'C:\Retalix\HQ\uploadfile_host\a\'  
		  ,@Expoprtfilename nvarchar(200)
		  ,@bal int =20; --per 6  point  for 1 rmb
    declare @tableDate_cur varchar(6) ,@tableDate_pre varchar(6) 
	,@atd_Server nvarchar(max) ='ATD_Shell'		
	,@ServerHost nvarchar(max)='HOST_Shell_1'
	,@loyalty_server varchar(max)='Loyalty_Shell_1'
	,@sql_text  nvarchar(max)
	,@sql_text_org nvarchar(max)
	, @MatrixMemberId1 int=1
	 
	
	--加载新录入数据
	--定义游标
	declare point_detail_cur cursor
	for 
	select PosTranInternalKey,AccountInternalKey,BuyingUnitInternalKey,MatrixMemberId,
	PosDateTime,ProcessDate,EarnValue,RedeemValue,InitialValue,ExpirationDate,ReasonCode,
	Remarks,SourcePosTranInternalKey from Loyalty_Shell_1.dbo.CRM_POSAccountsActivity  cpaa
	 where   not exists
	(select  cpaa1.PosTranInternalKey  from report_data.dbo.CRM_POSAccountsActivity cpaa1 
	 where cpaa1.PosTranInternalKey=cpaa.PosTranInternalKey)  -- and BuyingUnitInternalKey=1003
	 order by PosTranInternalKey,BuyingUnitInternalKey ;
	open point_detail_cur
	fetch next from point_detail_cur  into @posTranInternalKey,@AccountInternalKey,@BuyingUnitInternalKey,@MatrixMemberId,
	@PosDateTime,@ProcessDate,@EarnValue,@RedeemValue,@InitialValue,@ExpirationDate,@ReasonCode,
	@Remarks,@SourcePosTranInternalKey

	while @@fetch_STATUS = 0   
	begin
	set @balance=0;
	select  @balance=balance ,@pos_key=cpaa1.PosTranInternalKey  from report_data.dbo.CRM_POSAccountsActivity cpaa1 
	   where cpaa1.PosTranInternalKey in (select  max(cp1.PosTranInternalKey)
	      from report_data.dbo.CRM_POSAccountsActivity cp1 where cp1.BuyingUnitInternalKey=@BuyingUnitInternalKey 
		  and cp1.AccountInternalKey=@AccountInternalKey  and MatrixMemberId=@MatrixMemberId )

		
  if @@rowcount=1  
   update  report_data.dbo.CRM_POSAccountsActivity set end_date=@PosDateTime where PosTranInternalKey=@pos_key;
    -- 插入新积分或兑换数据
	  set @balance=@balance+@EarnValue-@RedeemValue;
		  insert into report_data.dbo.CRM_POSAccountsActivity (PosTranInternalKey,AccountInternalKey,BuyingUnitInternalKey,MatrixMemberId,
	PosDateTime,ProcessDate,EarnValue,RedeemValue,InitialValue,ExpirationDate,ReasonCode,
	Remarks,SourcePosTranInternalKey,balance,begin_date,end_date) values( @posTranInternalKey,@AccountInternalKey,@BuyingUnitInternalKey,@MatrixMemberId,
	@PosDateTime,@ProcessDate,@EarnValue,@RedeemValue,@InitialValue,@ExpirationDate,@ReasonCode,
	@Remarks,@SourcePosTranInternalKey,@balance,@PosDateTime,'2099-12-31')
         fetch next from point_detail_cur  into @posTranInternalKey,@AccountInternalKey,@BuyingUnitInternalKey,@MatrixMemberId,
	@PosDateTime,@ProcessDate,@EarnValue,@RedeemValue,@InitialValue,@ExpirationDate,@ReasonCode,
	@Remarks,@SourcePosTranInternalKey

	end;
	 
	close point_detail_cur              
	deallocate point_detail_cur
	
	--提取会员积分

	    delete report_data.dbo.R10_member_list_1;
	set @sql_text_org=N'   INSERT INTO report_data.[dbo].[R10_member_list_1]
           ([member_card_no]    --1
		   ,member_reg_comp_code   --2
		   ,member_reg_store_code   --3
		   ,member_reg_store         --3.1
		  , reg_store_date            --4
           ,[reg_date]               --4.1
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
,s.storename  regstore         --3.1会员注册默认油站
,convert(varchar(10),cmsa.updatedDate,120)              --4 会员注册油站日期
,convert(varchar(10),cm.StartDate,120)          --4.1 -注册日期
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
   left join (	select cpaa.buyingUnitInternalKey,cpaa.balance  
				 FROM [report_data].[dbo].[CRM_POSAccountsActivity]  cpaa 
				 where   convert(varchar(10),cpaa.begin_date,120)<=@business_date
				  and convert(varchar(10),end_date,120)>@business_date and AccountInternalKey=2 
					 )    buaa 
    on buaa.BuyingUnitInternalKey=cm.BuyingUnitInternalKey  
  left join  [Loyalty_Shell_1].[dbo].[CRM_Clubcard]  cc on  cc.ClubCardId=cm.ExternalMemberKey  
  left join  [Loyalty_Shell_1].[dbo].CRM_BuyingUnit crmb on cm.BuyingUnitInternalKey=crmb.BuyingUnitInternalKey 
  --and  crmb.MatrixMemberId=cc.MatrixMemberId
  left join  [Loyalty_Shell_1].[dbo].[State_MP]  sp on crmb.State=sp.StateId and sp.LanguageId=8
  inner join Loyalty_Shell_1. [dbo].[CRM_MemberSegment] cms on cms.MemberInternalKey=cm.MemberInternalKey
                  and  cms.SegmentInternalKey in (3058,3059,3060,3057,3071,3072,3073)   and  cms.MatrixMemberId=@MatrixMemberId
 inner join  Loyalty_Shell_1.[dbo].[CRM_Segment] cs on cs.SegmentInternalKey=cms.SegmentInternalKey and  cs.MatrixMemberId=cms.MatrixMemberId
   
   
   where  cm.externalmemberkey  is not null  
  order by cm.StartDate'

 -- print @sql_text_org
	set @sql_text=@sql_text_org;

	--set @sql_text = replace(@sql_text,'201704',@TableDate_cur);
	set @sql_text = replace(@sql_text,'@business_date',''''+@business_date+'''');
	print @sql_text
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId1);
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
	print @sql_text;

	exec(@sql_text);
	  set  @table='R10_member_list_1';
set  @Expoprtfilename=@filepath+@table+'\'+@table+@business_date+'-'+@business_date+'.csv';
exec  report_data.[dbo].est_export_cvs @table,@Server,@Expoprtfilename;	
  
END

GO
