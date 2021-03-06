USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[CMS_GetMemberCoupinAndRegPromotion]    Script Date: 1/19/2022 9:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* =============================================
6.1.	查询会员账户下的优惠券、注册促销
	参数：会员卡号(loyaltyID)、Retail ID、类型（0：返回优惠券与注册促销的，1：返回优惠券，2：返回注册促销）、状态（	1	Registered
	2	Redeemed
	3	Expired
	4   cancel）
）
	返回值：会员卡号；返回包括2部分：优惠券、注册促销，每部分里包含可包含多条数据，字段有：
“优惠券”：促销ID、促销名称、促销结束时间、券码、券名、券开始时间、券结束时间、状态
“注册促销”：促销ID、促销名称、促销结束时间、券码（空值）、券名（空值）、券开始时间（在会员账户下注册促销开始时间）、券结束时间（在会员账户下注册促销结束时间）、状态
  -- reg 7004900087865910110
  --document 7004900067201266210
declare 	@ClubCardId  nvarchar(50)='7004900067201266210',
   	@RetailId nvarchar(10)='5',
	@type   int='0' ,
	@status int='1'
	,@json  nvarchar(max)  
	exec  CMS_GetMemberCoupinAndRegPromotion  @ClubCardId,@RetailId,@type,@status,@Json  output

-- Author:		<Author,,Name>
-- Create date: 2020-09-13
-- Description:	<Description,,>
-- =============================================
*/
create  PROCEDURE  [dbo].[CMS_GetMemberCoupinAndRegPromotion]
	@ClubCardId  nvarchar(50),
	@RetailId nvarchar(10),
	@type   int ,
	@status int,
	@Json nvarchar(max) output
AS
BEGIN
	
      DECLARE @table              VARCHAR(max) ='promotion_list',
              @Server             VARCHAR(max) ='Loyalty_Shell_1.dbo.',
              @FilePath           NVARCHAR(400)= 'C:\Retalix\HQ\uploadfile_host\a\',
              @Expoprtfilename    NVARCHAR(300),
              @bal                INT =50,
              @loyalty_server     VARCHAR(max)='Loyalty_Shell_1',
              @sql_text           NVARCHAR(max),
              @sql_text_org       NVARCHAR(max),
            
              @atd_server         VARCHAR(50)
			  

      SELECT @atd_Server = c.paraValue0
      FROM   dbo.param_config c
      WHERE  c.paraName = 'atd_Server';

      SELECT @loyalty_server = c.paraValue0
      FROM   dbo.param_config c
      WHERE  c.paraName = 'loyalty_server';

   




    
 

      --优惠券
    

      SET @sql_text_org=N'  select  type , cardid,PromotionHeaderId,PromotionHeaderDescription,PromotionHeaderEndDate ,Barcode, InstanceDescription,StartDate,EndDate,Status, DocumentId 
	   from  (

select  1 as type
, cbu.ExternalBuyingUnit as cardid
 ,ph.PromotionHeaderId 
 ,ph.PromotionHeaderDescription
 ,ph.PromotionHeaderEndDate
 ,cld.Barcode --2
 ,ci.InstanceDescription	--3
 ,cld.StartDate
 ,cld.EndDate
 ,CASE
                 WHEN cLD.Status = 0
                  AND Getdate() > cLD.EndDate THEN 3 -- Expired
				  when cld.Status=2  then 2
             ELSE cLD.Status+1   -- 1=Active, 2=Redeem,   2=Cancel,3 Future 3 -- Expired
           END AS Status
 , cld.DocumentId

   from  	 [Loyalty_Shell_1].[dbo].[CRM_LoyaltyDocuments]  cld 
left join Loyalty_Shell_1..CRM_BuyingUnit cbu on cld.IssuedBuyingUnitInternalKey=cbu.BuyingUnitInternalKey and cld.MatrixMemberId=cbu.MatrixMemberId
  left join Loyalty_Shell_1..CRM_Member cm  on cm.BuyingUnitInternalKey=cbu.BuyingUnitInternalKey
left join Loyalty_Shell_1..CRM_Clubcard cc on cc.MemberInternalKey=cm.MemberInternalKey
    left join [Promotion_Shell].[dbo].[CouponInstance] ci on cld.DocumentId=ci.DocumentId
		left join report_data..PromotionHeader_PR ph on ph.RequiredCoupon=1 and ph.InstanceInternalKey=ci.InstanceInternalKey	

  left join RetailCode_MP  rc on rc.MatrixMemberId=cbu.MatrixMemberId
    left  join report_data.[dbo].[PromotionHeader_PR] phpr 
	on phpr.PromotionHeaderId=cld.PromotionHeaderId  and  phpr.MatrixMemberId=cbu.MatrixMemberId
where  ( CASE
                 WHEN cLD.Status = 0
                  AND convert(date,convert(varchar(10),Getdate(),120),120) > cLD.EndDate THEN 3 -- Expired
				  when cld.Status=2  then 2
             ELSE cLD.Status+1   -- 1=Active, 2=Redeem,   2=Cancel,3 Future 3 -- Expired
           END =@status )  and rc.RetailerId=@RetailId and     cc.ClubCardId=@ClubCardId
 and (@type=0 or @type=1)
 '
      SET @sql_text=@sql_text_org;
   
      SET @sql_text = Replace(@sql_text, '@status', @status);
	        SET @sql_text = Replace(@sql_text, '@type', @type);
	    SET @sql_text = Replace(@sql_text, '@ClubCardId',''''+ @ClubCardId+'''');
         SET @sql_text = Replace(@sql_text, 'ATD_Shell', @atd_Server)
      SET @sql_text = Replace(@sql_text, 'Loyalty_Shell_1', @loyalty_server);
   
      	set @sql_text = replace(@sql_text,'@RetailId' ,''''+@RetailId+'''');

 SELECT @sql_text
   --   EXEC(@sql_text);

--EXEC report_data..[SerializeJSON]   @sql_text,@json output
--set @json=N'{"reg":'+@json+N'}'
 print @json

    

--	select * from  	 [Loyalty_Shell_1].[dbo].[CRM_LoyaltyDocuments]  cld 

--“注册促销”：促销ID、促销名称、促销结束时间、券码（空值）、券名（空值）、券开始时间（在会员账户下注册促销开始时间）、券结束时间（在会员账户下注册促销结束时间）、状态


	
		


   SET @sql_text_org=@sql_text_org+N' union all 

select  2 type 
 ,cbu.ExternalBuyingUnit   --1
,cbup.PromotionHeaderId       --2
, ph.PromotionHeaderDescription
,ph.PromotionHeaderEndDate
,null as regcode
,null as regname
,cbup.RegistrationStartDate
,cbup.RegistrationEndDate
,case when  cbup.Active=1 and RegistrationEndDate>getdate() then 1  when  cbup.Active=2 then 2
   when cbup.Active=1 and RegistrationEndDate<getdate() then 3 else  4 end     as status
,1 as  DocumentId	
 from Loyalty_Shell_1..CRM_BuyingUnitPromotion (nolock) cbup
left join Loyalty_Shell_1..CRM_BuyingUnit cbu  (nolock)  on cbu.BuyingUnitInternalKey=cbup.BuyingUnitInternalKey 
left join Loyalty_Shell_1..CRM_Member cm  on cm.BuyingUnitInternalKey=cbu.BuyingUnitInternalKey
left join Loyalty_Shell_1..CRM_Clubcard cc on cc.MemberInternalKey=cm.MemberInternalKey
left join report_data..PromotionHeader_PR ph on cbup.MatrixMemberId=ph.MatrixMemberId and cbup.PromotionHeaderId=ph.PromotionHeaderId
	left join RetailCode_MP  rc on rc.MatrixMemberId=cbu.MatrixMemberId 
 
WHERE   (case when  cbup.Active=1 and RegistrationEndDate>getdate() then 1  when  cbup.Active=2 then 2
   when cbup.Active=1 and RegistrationEndDate<getdate() then 3 else  4 end  )    =@status
    and  cc.ClubCardId=@ClubCardId
	 and (@type=0 or @type=2)  and rc.RetailerId=@RetailId 
 
'
set @sql_text_org=@sql_text_org+') a  ';
  SET @sql_text=@sql_text_org;
   
         SET @sql_text = Replace(@sql_text, '@status', @status);
	        SET @sql_text = Replace(@sql_text, '@type', @type);
	    SET @sql_text = Replace(@sql_text, '@ClubCardId',''''+ @ClubCardId+'''');
         SET @sql_text = Replace(@sql_text, 'ATD_Shell', @atd_Server)
      SET @sql_text = Replace(@sql_text, 'Loyalty_Shell_1', @loyalty_server);
   
    	set @sql_text = replace(@sql_text,'@RetailId' ,''''+@RetailId+'''');  

     SELECT @sql_text
 

   exec ( @sql_text)
 


EXEC report_data..[SerializeJSON]   @sql_text,@json output
set @json=N'{"info":'+@json+N'}'
 print @json


  END 

 




GO
