USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[member_list]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/****** Object:  StoredProcedure [dbo].[est]    Script Date: 2017/3/2 18:01:20 ******/

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	本过程提取会员信息,在0点运行.
CREATE  PROCEDURE [dbo].[member_list]
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
	

   ----R10-member list
   --insert into member_list
   delete report_data.dbo.R10_member_list;
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
,case when cm.Gender=1 then N'''+N'男'+''' when cm.gender=0 then  N'''+N'女'+'''  end  as xb --11
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
	set @sql_text = replace(@sql_text,'@bal',@bal);
	set @sql_text = replace(@sql_text,'ATD_Shell',@atd_Server);
	set @sql_text = replace(@sql_text,'Loyalty_Shell_1',@loyalty_server);

	exec(@sql_text);
	print @sql_text
   set  @table='r10_member_list';
set  @Expoprtfilename=@filepath+@table+'\'+@table+@createDate_begin+'-'+@business_end+'.csv';
exec  report_data.[dbo].est_export_cvs @table,@Server,@Expoprtfilename;	
end;



GO
