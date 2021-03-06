USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[member_point_redem0221]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description: 积分进销存	完成积分兑换功能,首先添加过期积分到积分兑换明细表,置过期积分balance为0
--计算兑换积分,显示未过期的积分.
-- =============================================
CREATE  PROCEDURE  [dbo].[member_point_redem0221]
--	@business_date varchar(10)	
	
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
	 
	 --插入获得积分记录
	 insert into report_data.dbo.CRM_POSAccountsActivityReward(PosTranInternalKey,AccountInternalKey,BuyingUnitInternalKey,MatrixMemberId,
	PosDateTime,ProcessDate,EarnValue,InitialValue,ExpirationDate,SourcePosTranInternalKey)
	
	select PosTranInternalKey,AccountInternalKey,BuyingUnitInternalKey,MatrixMemberId,
	PosDateTime,ProcessDate,EarnValue,InitialValue,ExpirationDate,SourcePosTranInternalKey 
	 from Loyalty_Shell_1.dbo.CRM_POSAccountsActivity  cpaa  (nolock) --loyalty  
	 where   not exists
	(select  cpaa1.PosTranInternalKey  from report_data.dbo.CRM_POSAccountsActivityreward cpaa1  (nolock) --reportdata  
	   where cpaa1.PosTranInternalKey=cpaa.PosTranInternalKey  and cpaa.MatrixMemberId=cpaa1.MatrixMemberId)
	   and cpaa.EarnValue>0  and cpaa.AccountInternalKey=2
	
	--置过期积分balance为0
/*	insert  report_data.[dbo].[CRM_POSAccountsActivitRedemDetail]
	   ( posTranInternalKey,AccountInternalKey,BuyingUnitInternalKey,MatrixMemberId,
	PosDateTime,ProcessDate,EarnValue,InitialValue,ExpirationDate,ReasonCode,
	Remarks,SourcePosTranInternalKey,redemPosTranInternalKey,balance,redembalance)
	 select  posTranInternalKey,AccountInternalKey,BuyingUnitInternalKey,MatrixMemberId,
	PosDateTime,getdate(), 0,0,ExpirationDate,ReasonCode,
	Remarks,SourcePosTranInternalKey, -999,0,balance 
	 from report_data.dbo.CRM_POSAccountsActivityReward
	 where   ExpirationDate<convert(varchar(10),getdate(),120)
	     and balance>0;  --插入过期失效的积分,标志为 redemPosTranInternalKey 为-999
	update report_data.dbo.CRM_POSAccountsActivityReward  set balance=0 
	where   ExpirationDate<convert(varchar(10),getdate(),120)  and balance>0;  --置过期失效的积分为零


	--加载新录入数据
	--定义游标
	declare point_detail_cur cursor
	for 
	select PosTranInternalKey,AccountInternalKey,BuyingUnitInternalKey,MatrixMemberId,
	PosDateTime,ProcessDate,EarnValue,RedeemValue,InitialValue,ExpirationDate,ReasonCode,
	Remarks,SourcePosTranInternalKey from Loyalty_Shell_1.dbo.CRM_POSAccountsActivity  cpaa
	 where   not exists
	(select  PosTranInternalKey  from
	(select PosTranInternalKey  from  [report_data].dbo.[CRM_POSAccountsActivityReward]
	 union  all 
	select PosTranInternalKey  from   [report_data].[dbo].[CRM_POSAccountsredem] )
	   cpaa1 
	 where cpaa1.PosTranInternalKey=cpaa.PosTranInternalKey)  -- and BuyingUnitInternalKey=1003
	 order by PosTranInternalKey,BuyingUnitInternalKey ;
	open point_detail_cur
	fetch next from point_detail_cur  into @posTranInternalKey,@AccountInternalKey,@BuyingUnitInternalKey,@MatrixMemberId,
	@PosDateTime,@ProcessDate,@EarnValue,@RedeemValue,@InitialValue,@ExpirationDate,@ReasonCode,
	@Remarks,@SourcePosTranInternalKey

	while @@fetch_STATUS = 0   
	begin
	set @balance=0;

 if @EarnValue<>0 
	insert  report_data.dbo.CRM_POSAccountsActivityReward(PosTranInternalKey,AccountInternalKey,BuyingUnitInternalKey,MatrixMemberId,
	PosDateTime,ProcessDate,EarnValue,RedeemValue,InitialValue,ExpirationDate,ReasonCode,
	Remarks,SourcePosTranInternalKey,balance,begin_date,end_date)
	 values( @posTranInternalKey,@AccountInternalKey,@BuyingUnitInternalKey,@MatrixMemberId,
	@PosDateTime,@ProcessDate,@EarnValue,0,@InitialValue,@ExpirationDate,@ReasonCode,
	@Remarks,@SourcePosTranInternalKey,@EarnValue,@PosDateTime,'2099-12-31');
if @RedeemValue<>0 
insert into report_data.dbo.CRM_POSAccountsRedem(PosTranInternalKey,AccountInternalKey,BuyingUnitInternalKey,MatrixMemberId,
	PosDateTime,ProcessDate,EarnValue,RedeemValue,InitialValue,ExpirationDate,ReasonCode,
	Remarks,SourcePosTranInternalKey,balance,begin_date,end_date) values( @posTranInternalKey,@AccountInternalKey,@BuyingUnitInternalKey,@MatrixMemberId,
	@PosDateTime,@ProcessDate,0,@RedeemValue,@InitialValue,@ExpirationDate,@ReasonCode,
	@Remarks,@SourcePosTranInternalKey,0,@PosDateTime,'2099-12-31')

	
	--计算有效积分
	  exec calculatePoint  @BuyingUnitInternalKey,@PosDateTime,@RedeemValue,@PosTranInternalKey 

	fetch next from point_detail_cur  into @posTranInternalKey,@AccountInternalKey,@BuyingUnitInternalKey,@MatrixMemberId,
	@PosDateTime,@ProcessDate,@EarnValue,@RedeemValue,@InitialValue,@ExpirationDate,@ReasonCode,
	@Remarks,@SourcePosTranInternalKey

	end;
	 
	close point_detail_cur              
	deallocate point_detail_cur
	
	--提取会员积分
*/
	
END


GO
