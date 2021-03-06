USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[update_report_CRM_POSAccountsActivity]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
  CREATE procedure  [dbo].[update_report_CRM_POSAccountsActivity] as
declare  @createdate_end1 varchar(10) ;
declare @PosTranInternalKey  [int] ,
        @MaxPosTranInternalKey int ,
    	@AccountInternalKey [int] ,
		@BuyingUnitInternalKey [int] ,
	    @MatrixMember_cUR [smallint],
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
		@pos_key int,
		@EachEtractMemberCount int ;
	--	@business_date varchar(10)	;
        set @EachEtractMemberCount=800000; 
		set @balance=0;
		
	 
	
	 
	    declare   @table VARCHAR(max) ='promotion_list_1'
		
		  ,@Server VARCHAR(max)   ='Loyalty_Shell_1.dbo.'
		  ,@FilePath NVARCHAR(300)=  'M:\upload\'  
		  ,@Expoprtfilename nvarchar(200)
		  ,@bal int =20; --per 6  point  for 1 rmb
    declare @tableDate_cur varchar(6) ,@tableDate_pre varchar(6) 
	,@atd_Server nvarchar(max)  		
	,@ServerHost nvarchar(max) 
	,@loyalty_server varchar(max) 
	,@sql_text  nvarchar(max)
	,@sql_text_org nvarchar(max)
	
 
	 
  ---计算会员积分 当前时间，不区分maxtrxmemberID
	--加载新录入数据
	--定义游标

  select @MaxPosTranInternalKey=max(cpaa.PosTranInternalKey)   from report_data..CRM_POSAccountsActivity cpaa
 	 if @MaxPosTranInternalKey is null 
	   set  @MaxPosTranInternalKey=0 

 	declare point_detail_cur cursor  static
	for 	select PosTranInternalKey,AccountInternalKey,BuyingUnitInternalKey,MatrixMemberId,
	PosDateTime,ProcessDate,EarnValue,RedeemValue,InitialValue,ExpirationDate,ReasonCode,
	Remarks,SourcePosTranInternalKey 
	-- into #point_detail 
	 from Loyalty_Shell_uat..CRM_POSAccountsActivity  cpaa  (nolock) --loyalty  
	 where     not exists
	(select  cpaa1.PosTranInternalKey  from report_data.dbo.CRM_POSAccountsActivity cpaa1  (nolock) --reportdata  
	
	   where  cpaa1.PosTranInternalKey=cpaa.PosTranInternalKey -- and    cpaa1.ProcessDate>getdate()-5 -- and cpaa.MatrixMemberId=cpaa1.MatrixMemberId
	   )  
	   and cpaa.ProcessDate>getdate()-15 and cpaa.PosDateTime<>'2021-04-06'  
   --   cpaa.PosTranInternalKey>@MaxPosTranInternalKey
	 order by PosTranInternalKey,BuyingUnitInternalKey ;

	
	
	
	open point_detail_cur
	fetch next from point_detail_cur  into @posTranInternalKey,@AccountInternalKey,@BuyingUnitInternalKey,@MatrixMember_cUR,
	@PosDateTime,@ProcessDate,@EarnValue,@RedeemValue,@InitialValue,@ExpirationDate,@ReasonCode,
	@Remarks,@SourcePosTranInternalKey

	while @@fetch_STATUS = 0   
	begin
	set @balance=0;
	select  @balance=balance ,@pos_key=cpaa1.PosTranInternalKey  from report_data.dbo.CRM_POSAccountsActivity cpaa1 (nolock)
	   where cpaa1.PosTranInternalKey in (select  max(cp1.PosTranInternalKey)
	      from report_data.dbo.CRM_POSAccountsActivity cp1 (nolock) where cp1.BuyingUnitInternalKey=@BuyingUnitInternalKey 
		  and cp1.AccountInternalKey=@AccountInternalKey  --and
		  -- MatrixMemberId=@MatrixMemberId  --2017-11-22 change zyp
		 --  MatrixMemberId=@MatrixMember_cUR  --2017-11-22 change zyp 2019
		   )  and  cpaa1.AccountInternalKey=@AccountInternalKey --2018-03-20 change zyp


		
  if @@rowcount=1  
   update  report_data.dbo.CRM_POSAccountsActivity set end_date=@ProcessDate where PosTranInternalKey=@pos_key
   and AccountInternalKey=@AccountInternalKey ; --2018-03-20 change zyp
    -- 插入新积分或兑换数据
	  set @balance=@balance+@EarnValue-@RedeemValue;
		  insert into report_data.dbo.CRM_POSAccountsActivity (PosTranInternalKey,AccountInternalKey,BuyingUnitInternalKey,MatrixMemberId,
	PosDateTime,ProcessDate,EarnValue,RedeemValue,InitialValue,ExpirationDate,ReasonCode,
	Remarks,SourcePosTranInternalKey,balance,begin_date,end_date) values( @posTranInternalKey,@AccountInternalKey,@BuyingUnitInternalKey,@MatrixMember_cUR,
	@PosDateTime,@ProcessDate,@EarnValue,@RedeemValue,@InitialValue,@ExpirationDate,@ReasonCode,
	@Remarks,@SourcePosTranInternalKey,@balance,@ProcessDate,'2099-12-31')
     
	 fetch next from point_detail_cur  into @posTranInternalKey,@AccountInternalKey,@BuyingUnitInternalKey,@MatrixMember_cUR,
	@PosDateTime,@ProcessDate,@EarnValue,@RedeemValue,@InitialValue,@ExpirationDate,@ReasonCode,
	@Remarks,@SourcePosTranInternalKey

	end;
	
	close point_detail_cur              
	deallocate point_detail_cur

GO
