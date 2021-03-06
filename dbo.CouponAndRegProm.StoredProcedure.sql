USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[CouponAndRegProm]    Script Date: 1/19/2022 9:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	优惠券与注册促销导出
-- exec CouponAndRegProm  '2019-08-01' ,1
-- =============================================
CREATE  PROCEDURE [dbo].[CouponAndRegProm] @businessDate   VARCHAR(10),
@matrixMemberId INT
                                           
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
              @first_businessDate VARCHAR(10)=Substring(@businessDate, 1, 8) + '01',
              @end_businessDate   VARCHAR(10)=  convert(varchar(10),DATEADD(DAY,-1,DATEADD(MM,DATEDIFF(MM,0,@businessDate)+1,0)),120),
              @TableDate_cu       VARCHAR(10)=Substring(Replace(@businessDate, '-', ''), 1, 6), --设置年月
            
              @atd_server         VARCHAR(50)
			   , @RetailerId varchar(10)='0'
			   select @RetailerId=rc.RetailerId from  RetailCode_MP rc  where rc.MatrixMemberId=@matrixMemberId

  print  '@first_businessDate='+ @first_businessDate
  print '@end_businessDate='+ @end_businessDate
      SELECT @atd_Server = c.paraValue0
      FROM   dbo.param_config c
      WHERE  c.paraName = 'atd_Server';

      SELECT @loyalty_server = c.paraValue0
      FROM   dbo.param_config c
      WHERE  c.paraName = 'loyalty_server';

      SELECT @FilePath = erc.ExtractLocalPath
      FROM   extractReportConfig erc
      WHERE  erc.MatrixMemberId = @MatrixMemberId
	  declare @createdate varchar(10)=@businessDate
	  			 declare @createdDateNextday varchar(10)= dateadd( day,1,convert(date,@createdate,120))

	declare   @TableDate_pre  varchar(10)=SUBSTRING(REPLACE(convert( varchar,dateadd(month,-1,@createdate),120),'-',''),1,6) --设置年月 数据前一个月

 
   




    
 

      --优惠券
       TRUNCATE TABLE R53_coupon;

      SET @sql_text_org=N' insert into R53_coupon(

	   [qty]      --1
	    ,[CouponModelCode]  --2
      ,[CouponModelDesc]	--3
	   ,[IssueCouponPromotionId]   --4
	    ,[UseCouponPromotionId]     --5
          ,[clubcardid]               --6
      ,[barcode]                  --7
	  ,[startDate]                --8
      ,[status]                   --9
      ,[StatusDesc]               --10
      ,[UsingDate]                --11
	  ,[endDate]                  --12
      ,RegDateTime              --13 
      ,[RetailerId]  --14
	   ,[RegCompid]    --15
      ,[RegCompName]   --16
      ,[RegStoreId]    --17 
      ,[RegStoreName]   --18
      ,[TranCompId]     --19
      ,[TranCompName]   --20
      ,[TranStroeId]   --21
      ,[TranStoreName]  --22
      ,[city]           --23
      ,[TranId]         --24
      ,[BusinessDate]   --25
      ,[TranDateTime]  --26
      ,[PosId]         --27
	  ,create_Date       --28
	  ,PromotionDescription --29
	  )
  select   1                       --1
  ,  cld.DocumentId                --2
  ,ci.InstanceDescription          --3  
  ,cld.PromotionHeaderId           --4
  , 	ph.PromotionHeaderId usingPromotion   --5
  ,'''+''''+''''+'''+cm.ExternalMemberKey                        --6
   ,'''+''''+''''+'''+cld.Barcode                                --7
   , CONVERT(VARCHAR(10), CPDA.PosDateTime,120)  IssueDate              --8
   ,case when cld.Status=1 then  1  when  cld.Status=0 and cld.EndDate<getdate()  then  3  when   cld.Status=0 and cld.EndDate>=getdate()  then  0  else  9    END  --10  
                       --9             
  ,case when cld.Status=1 then  N'''+N'已使用' +''' when  cld.Status=0 and cld.EndDate<getdate()  then  N'''+N'已过期'+''' when   cld.Status=0 and cld.EndDate>=getdate()  then N'''+ N'未使用' +'''else +'''+'sdsd'+'''    END  --10  
  ,CONVERT(VARCHAR(10),cpda1.PosDateTime,120) UsingDate  --11
  ,CONVERT(VARCHAR(10),cld.EndDate,120)  ExpireDate  --12
  ,  convert(varchar(10),cm.StartDate,120)    --13
  ,rc.RetailerId     --14
  ,regStore.compid  --15
  ,regStore.comp   --16
  ,regStore.storeid --17
  ,regStore.StoreName --18
  ,gs.compID --19
  ,gs.comp    --20
  ,gs.storeid  --21
  ,gs.storename --22
  ,gs.city      --23
  ,cpt.TranId   --24
  ,convert(varchar(10),cpt.PosDateTime,120) --25
  ,convert(varchar(20),cpt.StartDateTime, 120)--26
  ,cpt.posId           --27
  ,convert(varchar(10),getdate(),120) as createdate 
  , phpr.PromotionHeaderDescription'
 SET @sql_text_org=@sql_text_org+N'  from  	 [Loyalty_Shell_1].[dbo].[CRM_LoyaltyDocuments]  cld 
    left join [Promotion_Shell].[dbo].[CouponInstance] ci on cld.DocumentId=ci.DocumentId and  cld.BusinessId=ci.BusinessId
 		left join [Loyalty_Shell_1].[dbo].[CRM_POSLoyaltyDocumentsActivity]  cpda 
	 on  cpda.DocumentInternalKey=cld.DocumentInternalKey and Action=0
 	left join [Loyalty_Shell_1].[dbo].[CRM_POSLoyaltyDocumentsActivity]  cpda1 
	 on  cpda1.DocumentInternalKey=cld.DocumentInternalKey and cpda1.Action=1
	 left join report_data..PromotionHeader_PR ph on ph.RequiredCoupon=1 and ph.InstanceInternalKey=ci.InstanceInternalKey
		-- left join  [Loyalty_Shell_1]..[CRM_POSPromotionActivity] cppa on cppa.PosTranInternalKey=cpda1.POSTranInternalKey

	 left join Loyalty_Shell_1..CRM_POSTran cpt  on  cpda1.POSTranInternalKey=cpt.POSTranInternalKey
  left join store_gs gs on gs.StoreInternalKey=cpt.StoreInternalKey and gs.MatrixMemberId=@MatrixMemberId
 left join Loyalty_Shell_1.dbo.CRM_Member cm on cld.IssuedBuyingUnitInternalKey=cm.BuyingUnitInternalKey
  left join RetailCode_MP  rc on rc.MatrixMemberId=@MatrixMemberId
  left join v_get_reg_compAndStore regStore on regStore.BuyingUnitInternalKey=cm.BuyingUnitInternalKey
   left  join report_data.[dbo].[PromotionHeader_PR] phpr 
	on phpr.PromotionHeaderId=cld.PromotionHeaderId  and  phpr.MatrixMemberId=@MatrixMemberId
where  cld.issueMatrixMemberId=@MatrixMemberId and (cpda.PosDateTime=convert(date,@businessDate,120) or  cpda1.PosDateTime=convert(date,@businessDate,120) or( cld.Status=0 and cld.EndDate=convert(date,@businessDate,120) ))  
 '
      SET @sql_text=@sql_text_org;
   
      SET @sql_text = Replace(@sql_text, '@MatrixMemberId', @MatrixMemberId);
         SET @sql_text = Replace(@sql_text, 'ATD_Shell', @atd_Server)
      SET @sql_text = Replace(@sql_text, 'Loyalty_Shell_1', @loyalty_server);
      SET @sql_text = Replace(@sql_text, '@businessDate', '''' + @businessDate + '''');
      	set @sql_text = replace(@sql_text,'@RetailerId' ,@RetailerId);
 SET @sql_text = Replace(@sql_text, '@TableDate_cu',''''+ @TableDate_cu+'''');

 SELECT @sql_text
      EXEC(@sql_text);


    

      SET @table='R53_coupon';
      SET @Expoprtfilename=@filepath + @table + '\' + @table + @businessDate
                           + '.csv';

      PRINT @Expoprtfilename

      EXEC report_data.[dbo].Est_export_cvs
        @table,
        @Server,
        @Expoprtfilename;




		
truncate  table R14_BuyingUnitProm;

   SET @sql_text_org=N' with  RegPromotionStore as (  select distinct ftc.BusinessDate,ftc.TillId,fth.StartDateTime, fth.TranId,  ftpra.PromotionId,ftc.StoreId,cm.BuyingUnitInternalKey,gs.storename,@businessDate  as  UsingDate
   from   ATD_Shell..FO_TranPromotionRewardApportionment201810  (nolock) ftpra 
left join ATD_Shell..FO_TranHeader201810 (nolock) fth on ftpra.TicketInternalKey=fth.TicketInternalKey
left join ATD_Shell..FO_TranCollection (nolock) ftc on ftc.CollectionInternalKey=fth.CollectionInternalKey
left join ATD_Shell..fo_trancard201810  (nolock)fc on fc.TicketInternalKey=fth.TicketInternalKey
left join Loyalty_Shell_1..CRM_Member  (nolock) cm on fc.CardId=cm.ExternalMemberKey
left join report_data..store_gs gs on gs.storeid=ftc.StoreId and gs.MatrixMemberId=@MatrixMemberId
where  ftc.RetailerId=@RetailerId  and 
 fth.CreatedDate>=convert(date,@createDate,120)   and  fth.CreatedDate<convert(date,@createdDateNextday,120) 
 union 
 select distinct ftc.BusinessDate,ftc.TillId,fth.StartDateTime, fth.TranId,  ftpra.PromotionId,ftc.StoreId,cm.BuyingUnitInternalKey,gs.storename,@businessDate  as  UsingDate
   from   ATD_Shell..FO_TranPromotionRewardApportionment201809 ftpra 
left join ATD_Shell..FO_TranHeader201809 (nolock) fth on ftpra.TicketInternalKey=fth.TicketInternalKey
left join ATD_Shell..FO_TranCollection(nolock) ftc on ftc.CollectionInternalKey=fth.CollectionInternalKey
left join ATD_Shell..fo_trancard201809 (nolock) fc on fc.TicketInternalKey=fth.TicketInternalKey
left join Loyalty_Shell_1..CRM_Member(nolock) cm on fc.CardId=cm.ExternalMemberKey
left join report_data..store_gs gs on gs.storeid=ftc.StoreId and gs.MatrixMemberId=@MatrixMemberId
where  ftc.RetailerId=@RetailerId  and 
 fth.CreatedDate>=convert(date,@createDate,120)   and  fth.CreatedDate<convert(date,@createdDateNextday,120) 

)
insert R14_BuyingUnitProm( [clubcardid]    --1
      ,[promotionId]                       --2
      ,[regStartDate]                       --3
      ,[status]                              --4
      ,[StatusDesc]                         --5
      ,[usingDate]                         --6
      ,[regEndDate]                        --7
       ,RegDateTime                               --8
      ,[createDate]                        --9
	   ,[RegCompid]                        --10
      ,[RegCompName]                       --11
      ,[RegStoreId]                        --12
      ,[RegStoreName]                      --13
      ,[TranCompId]                        --14
      ,[TranCompName]                      --15    
      ,[TranStroeId]                       --16
      ,[TranStoreName]                     --17   
      ,[city]                              --18
      ,[TranId]                            --29
      ,[BusinessDate]                      --20
      ,[TranDateTime]                      --21   
      ,[PosId]                             --22
	  ,promotionDescription
	  )
 
'
/*Id	Status
0	Unregistered
1	Registered
2	Redeemed
3	Expired
*/
 SET @sql_text_org=@sql_text_org+' select '''+''''+''''+'''+ cm.ExternalMemberKey   --1
,cbup.PromotionHeaderId       --2
,convert(varchar(10),cbup.RegistrationStartDate,120)   --3
, case when cbup.Active=1 and RegistrationEndDate>@businessDate then 0  when  cbup.Active=2 then 1
   when cbup.Active=1 and RegistrationEndDate<@businessDate then 3 else  9 end as Active  
, case when cbup.Active=1 and RegistrationEndDate>@businessDate then N'''+N'未使用'+    '''when  cbup.Active=2 then N'''+N'已使用'+'''
   when cbup.Active=1 and RegistrationEndDate<@businessDate then N'''+N'已过期'+''' else '''+'ss'+''' end as StatusDesc   --5
		,rps.UsingDate     --6
		,convert(varchar(10),cbup.RegistrationEndDate,120) ExpireDate   --7
      ,convert(varchar(10),cm.StartDate,120)   --8	
   ,convert(varchar(10),getdate(),120) as createdate  --9
  ,regStore.compid  --10
  ,regStore.comp   --11
  ,regStore.storeid --12
  ,regStore.StoreName --13
  ,gs.compID --14
  ,gs.comp    --15
  ,gs.storeid  --16
  ,gs.storename --17
  ,gs.city      --18
  ,rps.TranId   --19
  ,convert(varchar(10),rps.BusinessDate,120) --20
  ,convert(varchar(20),rps.StartDateTime, 120)--21
 , rps.tillId            --22
  , phpr.PromotionHeaderDescription --23
 from Loyalty_Shell_1..CRM_BuyingUnitPromotion (nolock) cbup
left join Loyalty_Shell_1..CRM_Member  (nolock) cm  on cbup.BuyingUnitInternalKey=cm.BuyingUnitInternalKey
left join report_data..PromotionHeader_PR ph on cbup.MatrixMemberId=ph.MatrixMemberId and cbup.PromotionHeaderId=ph.PromotionHeaderId
left join  RegPromotionStore rps  on rps.BuyingUnitInternalKey=cbup.BuyingUnitInternalKey and rps.PromotionId=cbup.PromotionHeaderId
left join report_data..store_gs gs on gs.storeid=rps.StoreId
  left join v_get_reg_compAndStore regStore on regStore.BuyingUnitInternalKey=cm.BuyingUnitInternalKey
  left  join report_data.[dbo].[PromotionHeader_PR] phpr 
	on phpr.PromotionHeaderId=cbup.PromotionHeaderId  and  phpr.MatrixMemberId=@MatrixMemberId
WHERE ((cbup.RegistrationStartDate=convert(date,@businessDate,120) AND   cbup.Active=1  )OR (CBUP.RegistrationEndDate=CONVERT(DATE,@businessDate,120) AND cbup.Active=1) 
 OR (cbup.Active=2  AND     cbup.UpdatedDate>=convert(date,@createDate,120)   and  cbup.UpdatedDate<convert(date,@createdDateNextday,120) 
  -- and rps.TranId is not null 
 ))  and cbup.MatrixMemberId=@MatrixMemberId  and  phpr.MatrixMemberId=@MatrixMemberId 
'
  SET @sql_text=@sql_text_org;
   
      SET @sql_text = Replace(@sql_text, '@MatrixMemberId', @MatrixMemberId);
         SET @sql_text = Replace(@sql_text, 'ATD_Shell', @atd_Server)
      SET @sql_text = Replace(@sql_text, 'Loyalty_Shell_1', @loyalty_server);
      SET @sql_text = Replace(@sql_text, '@businessDate', '''' + @businessDate + '''');
	  	set @sql_text = replace(@sql_text,'@createDate',''''+@createDate+'''');
	  	set @sql_text = replace(@sql_text,'@createdDateNextday',''''+@createdDateNextday+'''');
    	set @sql_text = replace(@sql_text,'@RetailerId' ,''''+@RetailerId+'''');  
 SET @sql_text = Replace(@sql_text, '201810', @TableDate_cu);
 SET @sql_text = Replace(@sql_text, '201809',  @TableDate_pre);
 SELECT @sql_text
      EXEC(@sql_text);   

      SET @table='R14_BuyingUnitProm';
      SET @Expoprtfilename=@filepath + @table + '\' + @table + @businessDate
                           + '.csv';

      PRINT @Expoprtfilename

      EXEC report_data.[dbo].Est_export_cvs
        @table,
        @Server,
        @Expoprtfilename;




  END 



GO
