USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[member_point_detail]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE  [dbo].[member_point_detail]
	@business_date varchar(10)	
,	@MatrixMemberId [smallint]

	
AS
BEGIN

declare  @createdate_end1 varchar(10) ;
declare @PosTranInternalKey  [int] ,
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
		
	 
	 --  set @business_date=convert(varchar(10),dateadd(day,-1,getdate()),120);
	 
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
	select @atd_Server=c.paraValue0   from dbo.param_config c  where c.paraName='atd_Server';
	select @ServerHost=c.paraValue0   from dbo.param_config c  where c.paraName='ServerHost';
	select @loyalty_server=c.paraValue0   from dbo.param_config c  where c.paraName='loyalty_server';

	select @FilePath=erc.ExtractLocalPath  from extractReportConfig erc where erc.MatrixMemberId=@MatrixMemberId
 
/*	在report_data中记账积分拉链表 修改为每10分钟记账一次  20190919	 
  ---计算会员积分 当前时间，不区分maxtrxmemberID
	--加载新录入数据
	--定义游标

 
 	 

 
 declare point_detail_cur cursor  static
	for 	select PosTranInternalKey,AccountInternalKey,BuyingUnitInternalKey,MatrixMemberId,
	PosDateTime,ProcessDate,EarnValue,RedeemValue,InitialValue,ExpirationDate,ReasonCode,
	Remarks,SourcePosTranInternalKey 
	-- into #point_detail 
	 from Loyalty_Shell_Prod.dbo.CRM_POSAccountsActivity  cpaa  (nolock) --loyalty  
	 where   not exists
	(select  cpaa1.PosTranInternalKey  from report_data.dbo.CRM_POSAccountsActivity cpaa1  (nolock) --reportdata  
	
	   where cpaa1.PosTranInternalKey=cpaa.PosTranInternalKey  -- and cpaa.MatrixMemberId=cpaa1.MatrixMemberId
	   ) 
	   --  AND cpaa.MatrixMemberId=@MatrixMemberId --   2017-11-22  change zyp

	 order by PosTranInternalKey,BuyingUnitInternalKey ;

	
	
	-- 	declare point_detail_cur cursor
	--for  --select *  from  #point_detail  order by PosTranInternalKey,BuyingUnitInternalKey ;

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
   */
	--提取会员积分

	    truncate table  report_data.dbo.R10_member_list;
	set @sql_text_org=N'   INSERT INTO report_data.[dbo].[R10_member_list]
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
		    ,[status]
           ,LastModifyDate     )                --14  20200527add   
		   select  cm.externalmemberkey          --1会员号码

		  , s.compid    compid            --2.0
,s.storeid   storeid           --3.0会员注册油站     
,s.storename  regstore         --3.1会员注册默认油站
,convert(varchar(10),s.updatedDate,120)              --4 会员注册油站日期
,convert(varchar(10),cm.StartDate,120)          --4.1 -注册日期
, matri.MatrixMemberName jv_seg               --5 所属JV会员组  
,s.comp    					-- 6公司代码
, crmb.city  city								    --7所在城市
, sp.StateName  prov								    --8所属省份
,crmb.POBox regchannel --9注册渠道
,convert(varchar(10),cm.birthdate,120)				--10
,case when cm.Gender=1 then N'''+N'男'+''' when cm.gender=2 then  N'''+N'女'+''' else '''+N'未知'+'''  end  as xb --11
,cm.MobilePhoneNumber           --手机号码      --12
 ,buaa.Balance                               -- 会员帐户余额     --13  
,cc.RestrictionId                           --卡状态        --14
 ,convert(varchar(10),begin_date,120) begin_date
    from       [Loyalty_Shell_1].[dbo].[CRM_Member] cm (nolock) 
  left join (		select cpaa.buyingUnitInternalKey,cpaa.balance,begin_date  
				 FROM [report_data].[dbo].[CRM_POSAccountsActivity]  cpaa (nolock)
				 where   convert(varchar(10),cpaa.begin_date,120)<=@business_date
				  and convert(varchar(10),end_date,120)>@business_date and AccountInternalKey=2 
					 and cpaa.AccountInternalKey=2 )    buaa  --2017-11-22 增加matrixid
    on buaa.BuyingUnitInternalKey=cm.BuyingUnitInternalKey  
  left join  [Loyalty_Shell_1].[dbo].[CRM_Clubcard]  cc (nolock) on  cc.ClubCardId=cm.ExternalMemberKey 
  left join  [Loyalty_Shell_1].[dbo].CRM_BuyingUnit crmb (nolock) on cm.BuyingUnitInternalKey=crmb.BuyingUnitInternalKey 
  --and  crmb.MatrixMemberId=cc.MatrixMemberId
  left join  [Loyalty_Shell_1].[dbo].[State_MP]  sp (nolock) on crmb.State=sp.StateId and sp.LanguageId=8

  inner join   report_data.[dbo].[v_get_reg_compAndStore]   s  (nolock) on s.BuyingUnitInternalKey=cm.BuyingUnitInternalKey --首次注册油站
 inner join report_data.dbo.[extractReportConfig]  matri  (nolock) on matri.MatrixMemberId=@MatrixMemberId
 
   where  cm.externalmemberkey  is not null and s.MatrixMemberId=@MatrixMemberId 
  -- and  buaa.Balance  is not null
   '

 -- print @sql_text_org
	set @sql_text=@sql_text_org;

	--set @sql_text = replace(@sql_text,'201704',@TableDate_cur);
	set @sql_text = replace(@sql_text,'@business_date',''''+@business_date+'''');
	print @sql_text
	set @sql_text = replace(@sql_text,'@MatrixMemberId' ,@MatrixMemberId);
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);
	print @sql_text;

	exec(@sql_text);

	declare @looptime int,@memberTotalCount int ,@i int;
	declare @member_card_no varchar(64);
	select @memberTotalCount=count(1) from R10_member_list;
	declare @loop float;
	set @loop=0.000
	set @loop=@memberTotalCount*1.000/ @EachEtractMemberCount
  
	set @looptime=ceiling(@loop);
	
	set @i=1 
	while @i<=@looptime 
	begin 
	set @sql_text=' if   exists   (select   *   from   dbo.sysobjects   where   id   =   object_id(N'''
	+'R10_member_list_'+ltrim(str(@i))+ ''')   and   OBJECTPROPERTY(id,   N'''+'IsUserTable'+''')   =   1)  

	   
  drop   table '+ 'R10_member_list_'+ltrim(str(@i));
  print @sql_text;
   exec( @sql_text);
     if @i=1 
	 set @sql_text=' select top '+ str(@EachEtractMemberCount) +'*  into   R10_member_list_'+ltrim(str(@i))
	  +' from R10_member_list  order by member_card_no';
	 else
 set @sql_text=' select top '+ str(@EachEtractMemberCount) +' * into   R10_member_list_'+ltrim(str(@i))
	  +' from R10_member_list where member_card_no> (select top 1 member_card_no from  R10_member_list_'+ltrim(str(@i-1))
	   +' order by member_card_no  desc)   order by member_card_no';

	 exec( @sql_text);

	 
	  print @sql_text;

	--set  @sql_text= 'select top 1 @member_card_no=member_card_no  from  R10_member_list_'+ltrim(str(@i)) +' order by  member_card_no  desc'
	--exec( @sql_text);

	
	
	  set  @table='R10_member_list_'+ltrim(str(@i));
	  
      set  @Expoprtfilename=@filepath+'R10_member_list'+'\'+@table+'_'+@business_date+'.csv';
      exec  report_data.[dbo].est_export_cvs @table,@Server,@Expoprtfilename;
	  set @i=@i+1;	
  end 
ENd



GO
