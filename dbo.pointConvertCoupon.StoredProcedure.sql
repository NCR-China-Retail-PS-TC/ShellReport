USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[pointConvertCoupon]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE  PROCEDURE [dbo].[pointConvertCoupon] @businessDate   VARCHAR(10),
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

 
      ---优惠券期初
      TRUNCATE TABLE document;

      SET @sql_text_org=N'
 	insert document(barcode,clubcardid,Status,reg_compid,reg_comp,reg_storeid,city,monthly,couponType,startDate,endDate,qty,point,pointJe,type)
	select  cld.barcode,cm.ExternalMemberKey ,
	cld.Status,
	s.compid    compid              --1
,s.comp      reg_comp                --2会员注册公司
,s.storeid   storeid                --3.0会员注册油站 
,s.city                             --城市
, @TableDate_cu  --月度
,N''' + N'积分兑劵'
                        + '''  couponType    --优惠券类型 
, convert(varchar(10),cld.StartDate,120)    --9发行日期
,convert(varchar(10),cld.EndDate,120)    --10过期日期
,1  as  qty                         --数量
,cpaa.redeemValue
,cpaa.RedeemValue/@bal  redeemValue    --金额
,1 as type
	 from  	 Loyalty_Shell_1.[dbo].[CRM_LoyaltyDocuments](nolock)  cld 
	left join [Loyalty_Shell_1].[dbo].[CRM_POSLoyaltyDocumentsActivity] (nolock)  cpda 
	 on  cpda.DocumentInternalKey=cld.DocumentInternalKey and Action=0
	 inner  join Loyalty_Shell_1.dbo.CRM_POSAccountsActivity (nolock)  cpaa
 on cpda.POSTranInternalKey=cpaa.PosTranInternalKey and cpaa.AccountInternalKey=2
  left join   report_data.[dbo].[v_get_reg_compAndStore]   s   on s.BuyingUnitInternalKey=cpaa.BuyingUnitInternalKey
	  and  s.MatrixMemberId=@MatrixMemberId  --首次注册油站
	  left join Loyalty_Shell_1.dbo.CRM_Member (nolock)  cm on  cm.BuyingUnitInternalKey=cld.IssuedBuyingUnitInternalKey

where   cld.Status=0 and  left(cld.Barcode,1)='''+'0'+''' and  cld.StartDate<@first_businessDate  and  cld.Enddate>= @first_businessDate  --发行日期小于本
 and  cld.IssueMatrixMemberId=@MatrixMemberId
--月初切未过期优惠券'
      SET @sql_text=@sql_text_org;
      SET @sql_text = Replace(@sql_text, '@MatrixMemberId', @MatrixMemberId);
      SET @sql_text = Replace(@sql_text, '@bal', @bal);
      SET @sql_text = Replace(@sql_text, 'Loyalty_Shell_1', @loyalty_server);
      SET @sql_text = Replace(@sql_text, '@first_businessDate', '''' + @first_businessDate + '''');
	     SET @sql_text = Replace(@sql_text, '@TableDate_cu',''''+ @TableDate_cu+'''');
  print @TableDate_cu
   EXEC(@sql_text);
print @sql_text
;






      PRINT N'---end 优惠券期初'

      --优惠券发行

   ---faxing 
      SET @sql_text_org=N'
 	insert document(barcode,clubcardid,cld.Status,reg_compid,reg_comp,reg_storeid,city,monthly
	,couponType,startDate,endDate,qty,point,pointJe,type)
	select   cld.barcode
	,cm.ExternalMemberKey ,
	cld.Status,
	s.compid    compid              --1
,s.comp      reg_comp                --2会员注册公司
,s.storeid   storeid                --3.0会员注册油站 
,s.city                             --城市
, @TableDate_cu  --月度  --月度
,N''' + N'积分兑劵'
                        + '''  couponType    --优惠券类型 
, convert(varchar(10),cld.StartDate,120)    --9发行日期
,convert(varchar(10),cld.EndDate,120)    --10过期日期
,1  as  qty                         --数量
,cpaa.redeemValue
,cpaa.RedeemValue/@bal  redeemValue    --金额
,2 as type
	 from  	 Loyalty_Shell_1.[dbo].[CRM_LoyaltyDocuments] (nolock)  cld 
	left join [Loyalty_Shell_1].[dbo].[CRM_POSLoyaltyDocumentsActivity](nolock)   cpda 
	 on  cpda.DocumentInternalKey=cld.DocumentInternalKey and Action=0
	 inner  join Loyalty_Shell_1.dbo.CRM_POSAccountsActivity (nolock)  cpaa
 on cpda.POSTranInternalKey=cpaa.PosTranInternalKey and cpaa.AccountInternalKey=2
  left join   report_data.[dbo].[v_get_reg_compAndStore]   s   on s.BuyingUnitInternalKey=cpaa.BuyingUnitInternalKey
	  and  s.MatrixMemberId=@MatrixMemberId  --首次注册油站
  left join Loyalty_Shell_1.dbo.CRM_Member(nolock)   cm on  cm.BuyingUnitInternalKey=cld.IssuedBuyingUnitInternalKey

where   left(cld.Barcode,1)='''+'0'+''' and  cld.StartDate>=convert(datetime,@first_businessDate)  and  cld.StartDate<convert
(datetime,@end_businessDate)+1  --发行日期小于本月初切未过期优惠券
   and  cld.IssueMatrixMemberId=@MatrixMemberId '
  SET @sql_text=@sql_text_org;
      SET @sql_text = Replace(@sql_text, '@MatrixMemberId', @MatrixMemberId);
      SET @sql_text = Replace(@sql_text, '@bal', @bal);
      SET @sql_text = Replace(@sql_text, 'Loyalty_Shell_1', @loyalty_server);
      SET @sql_text = Replace(@sql_text, '@first_businessDate', '''' + @first_businessDate + '''');
      SET @sql_text = Replace(@sql_text, '@end_businessDate', '''' + @end_businessDate + '''');
	  SET @sql_text = Replace(@sql_text, '@TableDate_cu',''''+ @TableDate_cu+'''');

 EXEC(@sql_text);




print @sql_text
      PRINT N'--end s优惠劵发行'

      --优惠券使用
       TRUNCATE TABLE document_use;

      SET @sql_text_org=N' insert into document_use(
	  barcode, Status,
  clubcardid,  ---0
  reg_compid,    --1
      reg_comp   ---2
	  ,reg_storeid  --3
	  ,reg_storeName --3.1
	  ,sal_comp --4
	  
	  ,sal_compid --5
	  ,sal_storeID --6
	  , sal_storeName --7
	  ,city --8
	  ,itemid   --9
	  ,itemname --10
	  ,qty          --11
	  ,couponType   --12 
	  ,point        --13  
	  ,act_pointJe    --14 
	  ,pointJe      --15
	  
	  ,using_date    --16
	  ,transactionId  --17
	   ,[promtion_id]				--18
       ,[promtion_group]			--19
	 ,promtion_ref                --20
	 ,Create_Date
	  )
  SELECT cld.barcode,cld.Status,  cm.externalmemberkey     --0会员号码
,s.compid    reg_compid            --1
,s.comp      reg_comp           --2会员注册公司
,s.storeid   storeid           --3会员注册油站  
,s.storeName   storename
,store.comp as sal_com                                  --4公司代码
,store.compid as sal_com_id                             --5公司代码
  ,store.storeid                 --6 油站代码
 ,store.storename as storename       -- 7油站名称
 
 ,store.city   city      --8城市
 , case when   item.firsttypeCode='''
                        + '10' + ''' then item.MainItemId
	else item.midtypeCode 
	end                         --9
	
,case when   item.firsttypeCode='''
                        + '10' + ''' then  item.FullName
	else item.midtype 	end     --10
 , 1 as qty                                      --11优惠券数量
 ,N''' + N'积分换券'
                        + '''                                    --12优惠券类型
 ,  cast(cpaa.RedeemValue*ftprd.RewardValue/ftprds.RewardValue as decimal(10,2))  point									--13
 ,cast(ftprd.RewardValue  as decimal(10,2)) pointje,                            --14兑换金额
cast (cpaa.RedeemValue*ftprd.RewardValue/ftprds.RewardValue/@bal as decimal(10,2)) redeemValue                         --15优惠券原始金额
,convert(varchar(10),ftc.BusinessDate ,120) BusinessDate                   --16营业日
,fth.tranid                               --17 交易id
 ,ftprd.PromotionId                                            --18促销id
	 ,phpr.ExternalGroupId --phpr.PromotionGroupId                                 --19促销组
	 ,substring(phpr.ExternalReferenceID,1,8)                             --20 外部促销id
   ,convert(varchar(10),fth.CreatedDate,120) '
  SET @sql_text_org=@sql_text_org+N'  from   ATD_Shell.dbo.FO_TranPromotionRewardApportionment201803(nolock)  ftprd  
   inner join (
    select   ftprd1.TicketInternalKey, ftprd1.PromotionId ,sum(ftprd1.RewardValue) RewardValue  
    from  [ATD_Shell].[dbo].[FO_TranPromotionRewardApportionment201803](nolock)  ftprd1  
	   where RewardMethodId in (5,3) 
	   group by ftprd1.TicketInternalKey, ftprd1.PromotionId  having sum(ftprd1.RewardValue)<>0 ) ftprds
	   on ftprds.TicketInternalKey=ftprd.TicketInternalKey and ftprds.PromotionId=ftprd.PromotionId
left join ATD_Shell.dbo.FO_TranHeader201803 (nolock)  fth on ftprd.TicketInternalKey=fth.TicketInternalKey
--left join ATD_Shell.dbo.FO_TranTender201803 (nolock)  ftt on fth.TicketInternalKey=ftt.TicketInternalKey
 inner  join [ATD_Shell].[dbo].[FO_TranCollection](nolock)  ftc on ftc.CollectionInternalKey=fth.CollectionInternalKey
left join  ATD_Shell.dbo.FO_TranPromotionIssuedDocument201803(nolock)  ftid on ftid.TicketInternalKey=ftprds.TicketInternalKey   and ftprds.PromotionId=ftid.PromotionId
 left join report_data.[dbo].[PromotionHeader_PR] phpr 	on phpr.PromotionHeaderId=ftprd.PromotionId and phpr.MatrixMemberId=@MatrixMemberId

 inner  join  [report_data].[dbo].store_gs store   on store.storeid=ftc.storeid and  store.MatrixMemberId=@MatrixMemberId 
   left join  Loyalty_Shell_1. [dbo].[CRM_POSTran](nolock)  cp 
    on cp.TranId=fth.TranId and cp.PosDateTime=ftc.BusinessDate and cp.StoreInternalKey=store.StoreInternalKey
	  and  cp.MatrixMemberId=@MatrixMemberId and cp.PosId=ftc.TillId
 
left join  Loyalty_Shell_1.dbo.CRM_LoyaltyDocuments(nolock)  cld  on 
 cld.Barcode=ftid.DocumentId    and cld.IssuedBuyingUnitInternalKey=cp.BuyingUnitInternalKey
left join [Loyalty_Shell_1].[dbo].[CRM_POSLoyaltyDocumentsActivity] (nolock)  cpda  on  cpda.DocumentInternalKey=cld.DocumentInternalKey and cpda.Action=0  --find i
inner  join Loyalty_Shell_1.dbo.CRM_POSAccountsActivity (nolock)  cpaa
 on cpda.POSTranInternalKey=cpaa.PosTranInternalKey and cpaa.AccountInternalKey=2

  left join    [Loyalty_Shell_1].[dbo].[CRM_Member](nolock)  cm  on cpaa.BuyingUnitInternalKey=cm.BuyingUnitInternalKey
 left join   report_data.[dbo].[v_get_reg_compAndStore]   s   on s.BuyingUnitInternalKey=cpaa.BuyingUnitInternalKey
	  and  s.MatrixMemberId=@MatrixMemberId --首次注册油站
--inner join [ATD_Shell].[dbo].[Tender_ALL] (nolock)  tender on ftt.StoreTenderId=tender.TenderId    and tender.MatrixMemberId=@MatrixMemberId
  --inner  join  [report_data].[dbo].store_gs store   on store.storeid=ftc.storeid and  store.MatrixMemberId=@MatrixMemberId 
left join  [report_data].[dbo].item_cat (nolock)  item 	on item.MainItemId=ftprd.EntityId  and item.MatrixMemberId=@MatrixMemberId

where   cld.Status=1 and left(cld.Barcode,1)='''+'0'+''' and   ftprd.RewardMethodId=5 
and  ftc.BusinessDate>=@first_businessDate and   ftc.BusinessDate<=@end_businessDate   
and  s.MatrixMemberId=@MatrixMemberId  '
      SET @sql_text=@sql_text_org;
      SET @sql_text = Replace(@sql_text, '201803', @TableDate_cu);
      SET @sql_text = Replace(@sql_text, '@MatrixMemberId', @MatrixMemberId);
      SET @sql_text = Replace(@sql_text, '@bal', @bal);
      SET @sql_text = Replace(@sql_text, 'ATD_Shell', @atd_Server)
      SET @sql_text = Replace(@sql_text, 'Loyalty_Shell_1', @loyalty_server);
      SET @sql_text = Replace(@sql_text, '@first_businessDate', '''' + @first_businessDate + '''');
      SET @sql_text = Replace(@sql_text, '@end_businessDate', '''' + @end_businessDate + '''');
 SET @sql_text = Replace(@sql_text, '@TableDate_cu',''''+ @TableDate_cu+'''');

 select @sql_text
      EXEC(@sql_text);

	  print ' @end_businessDate:='+ @end_businessDate
print @sql_text
      PRINT N'end --优惠券使用'

      ---优惠券期末
      SET @sql_text_org=N'
 	insert document(barcode,clubcardID,Status,reg_compid,reg_comp,reg_storeid,city,monthly,couponType,startDate,endDate,qty,point,pointJe,type)
	select cld.barcode,cm.ExternalMemberKey      --1会员卡号
	,cld.Status,
	s.compid    compid              --1
,s.comp      reg_comp                --2会员注册公司
,s.storeid   storeid                --3.0会员注册油站 
,s.city                             --城市
,@TableDate_cu  --月度
,N''' + N'积分兑劵'
                        + '''  couponType    --优惠券类型 
, convert(varchar(10),cld.StartDate,120)    --9发行日期
,convert(varchar(10),cld.EndDate,120)    --10过期日期
,1  as  qty                         --数量
,cpaa.RedeemValue
,cpaa.RedeemValue/@bal  redeemValue    --金额
,3 as type
	 from  	 Loyalty_Shell_1.[dbo].[CRM_LoyaltyDocuments](nolock)   cld 
	left join [Loyalty_Shell_1].[dbo].[CRM_POSLoyaltyDocumentsActivity] (nolock)  cpda 
	 on  cpda.DocumentInternalKey=cld.DocumentInternalKey and Action=0
	 inner  join Loyalty_Shell_1.dbo.CRM_POSAccountsActivity (nolock)  cpaa
 on cpda.POSTranInternalKey=cpaa.PosTranInternalKey and cpaa.AccountInternalKey=2
  left join   report_data.[dbo].[v_get_reg_compAndStore]   s   on s.BuyingUnitInternalKey=cpaa.BuyingUnitInternalKey
	  and  s.MatrixMemberId=@MatrixMemberId  --首次注册油站
	   left join Loyalty_Shell_1.dbo.CRM_Member (nolock)  cm on  cm.BuyingUnitInternalKey=cld.IssuedBuyingUnitInternalKey

where  cld.Status=0 and  left(cld.Barcode,1)='''+'0'+''' and  cld.StartDate<convert(datetime,@end_businessDate)+1  and  cld.Enddate>convert(datetime, 
@end_businessDate)+1  --发行日期小于本月未过期优惠券   
 and  cld.IssueMatrixMemberId=@MatrixMemberId    '
      SET @sql_text=@sql_text_org;
      SET @sql_text = Replace(@sql_text, '@MatrixMemberId', @MatrixMemberId);
      SET @sql_text = Replace(@sql_text, '@bal', @bal);
      SET @sql_text = Replace(@sql_text, 'Loyalty_Shell_1', @loyalty_server);
	 
      SET @sql_text = Replace(@sql_text, '@end_businessDate', '''' + @end_businessDate + '''');
	    SET @sql_text = Replace(@sql_text, '@TableDate_cu',''''+ @TableDate_cu+'''');
      EXEC(@sql_text);
	  print @sql_text
      PRINT N'--end --优惠券期末'

      ---优惠券到期
      SET @sql_text_org=N'	insert document(barcode,Status,
 clubcardid          --1
 , reg_compid		--2
 , reg_comp			--3
 ,reg_storeid			--4
 ,reg_storeName         --4.1
 ,sal_comp
 ,sal_storeid
 ,sal_storeName
 ,city				--5
 ,monthly			--6
 ,couponType		--7
 ,startDate			--8
 ,endDate			--9
 ,qty				--10
 ,point				--11
 ,pointJe			--12
 ,type
 )

	select cld.barcode,cld.Status,
	 cm.ExternalMemberKey ,      --1会员卡号
	 s.compid    compid            --2
,s.comp      reg_comp           --3会员注册公司
,s.storeid   storeid           --4会员注册油站 
,s.storename                    --4.1
,gs.compid
,gs.storeid
,gs.StoreName
,s.city                        --5-城市
,@TableDate_cu --6月度
,N''' + N'积分兑劵'
                        + '''   couponType       --7优惠券类型  
, convert(varchar(10),cld.StartDate,120)    --8发行日期
,convert(varchar(10),cld.EndDate,120)    --9过期日期 
,1  as  qty                            --10数量
,cpaa.RedeemValue                           --11
,cpaa.RedeemValue/@bal  redeemValue  ---12-兑换金额
,4 as type 
	 from  	 [Loyalty_Shell_1].[dbo].[CRM_LoyaltyDocuments] (nolock)  cld 
	left join [Loyalty_Shell_1].[dbo].[CRM_POSLoyaltyDocumentsActivity] (nolock)  cpda 
	 on  cpda.DocumentInternalKey=cld.DocumentInternalKey and Action=0
	 inner  join Loyalty_Shell_1.dbo.CRM_POSAccountsActivity (nolock)  cpaa
 on cpda.POSTranInternalKey=cpaa.PosTranInternalKey and cpaa.AccountInternalKey=2
  left join store_gs gs on gs.StoreInternalKey=cld.IssueStoreInternalKey and gs.MatrixMemberId=@MatrixMemberId
  left join   report_data.[dbo].[v_get_reg_compAndStore]   s   on s.BuyingUnitInternalKey=cpaa.BuyingUnitInternalKey
	  and  s.MatrixMemberId=@MatrixMemberId  --首次注册油站
 left join Loyalty_Shell_1.dbo.CRM_Member(nolock)  cm on cpaa.BuyingUnitInternalKey=cm.BuyingUnitInternalKey
where   left(cld.barcode,1)='''+'0'+'''  and  cld.EndDate>=@first_businessDate and  cld.EndDate<=@end_businessDate
  and cld.status=0     and  cld.IssueMatrixMemberId=@MatrixMemberId'
      SET @sql_text=@sql_text_org;
      SET @sql_text = Replace(@sql_text, '@MatrixMemberId', @MatrixMemberId);
      SET @sql_text = Replace(@sql_text, '@bal', @bal);
      SET @sql_text = Replace(@sql_text, 'Loyalty_Shell_1', @loyalty_server);
      SET @sql_text = Replace(@sql_text, '@first_businessDate', '''' + @first_businessDate + '''');
      SET @sql_text = Replace(@sql_text, '@end_businessDate', '''' + @end_businessDate + '''');
	   SET @sql_text = Replace(@sql_text, '@TableDate_cu',''''+ @TableDate_cu+'''');
	  print @sql_text
      EXEC(@sql_text);

	
      PRINT N'--end优惠券过期';

      DELETE R51_coupon_pss;

      WITH dc
           AS (SELECT dc.reg_compid,
                      dc.reg_comp,
                      monthly                          month,
                      Sum(Iif(type = 1, dc.qty, 0))     qc_qty,
                      Sum(Iif(type = 1, dc.pointJe, 0)) qc_je,
                      Sum(Iif(type = 2, dc.qty, 0))     issue_qty,
                      Sum(Iif(type = 2, dc.pointJe, 0)) issue_je,
                      Sum(Iif(type = 4, dc.qty, 0))     expire_qty,
                      Sum(Iif(type = 4, dc.pointJe, 0)) expire_je,
                      Sum(Iif(type = 3, dc.qty, 0))     end_qty,
                      Sum(Iif(type = 3, dc.pointJe, 0)) end_je
                    FROM   document dc
               GROUP  BY dc.reg_compid,
                         dc.reg_comp,monthly )
      INSERT INTO R51_coupon_pss
                  (reg_compid,
                   reg_comp,
                   month,
                   qc_qty,
                   qc_je,
                   issue_qty,
                   issue_je,
                   expire_qty,
                   expire_je,
                   end_qty,
                   end_je)
      SELECT dc.reg_compid,
             dc.reg_comp,
             month,
             qc_qty,
             qc_je,
             issue_qty,
             issue_je,
             expire_qty,
             expire_je,
             end_qty,
             end_je
      FROM   dc

      MERGE INTO R51_coupon_pss r51
      using(SELECT reg_compid,
                   reg_comp,
                   Sum(qty)         AS qty,
                   Sum(pointJe)     pointJe,
                   Sum(act_pointJe) act_pointJe
            FROM   document_use
            --WHERE  using_date = @businessDate
            GROUP  BY reg_compid,
                      reg_comp) du
      ON du.reg_compid = r51.reg_compid
         AND du.reg_comp = r51.reg_comp
      WHEN matched THEN
        UPDATE SET redeem_qty = du.qty,
                   redeem_je = du.pointJe,
                   redeem_action_je = act_pointje;

      SET @table='R51_coupon_pss';
      SET @Expoprtfilename=@filepath + @table + '\' + @table + @businessDate
                           + '.csv';

      PRINT  '555'+ @Expoprtfilename

      EXEC report_data.[dbo].Est_export_cvs
        @table,
        @Server,
        @Expoprtfilename;

      --优惠劵使用导出
        DELETE R41_document_use

      INSERT INTO R41_document_use
                  (member_card_no,
                   reg_compid,
                   reg_comp,
                   reg_storeid,
                   reg_storeName,
                   sal_compid,
                   sal_comp,
                   sal_storeID,
                   sal_storeName,
                   city,
                   using_date,
                   transactionId,
                   itemid,
                   itemname,
                   qty,
				   point,
                   pointJe,
                   act_pointJe,
				   ce,
				    [promtion_id]				--18
                   ,[promtion_group]			--19
	             ,promtion_ref                --20
				 ,create_Date
)
      SELECT du.clubcardid,
             reg_compid,
             reg_comp,
             du.reg_storeid,
             du.reg_storename,
             du.sal_compid,
             du.sal_comp,
             du.sal_storeID,
             du.sal_storeName,
             du.city,
             du.using_date,
             du.transactionId,
             du.itemid,
             du.itemname,
             Sum(qty)         AS qty,
			  Sum(point)     point,
             Sum(pointJe)     pointJe,
             Sum(act_pointJe) act_pointJe,
			 sum(pointJe-act_pointJe)   as   ce
			  ,[promtion_id]				--18
                   ,[promtion_group]			--19
	             ,promtion_ref                --20
                ,create_date
      FROM   document_use du
      WHERE  using_date = @businessDate
      GROUP  BY du.clubcardid,
                reg_compid,
                reg_comp,
                du.reg_storeid,
                du.reg_storename,
                du.sal_compid,
                du.sal_comp,
                du.sal_storeID,
                du.sal_storeName,
                du.city,
                du.using_date,
                du.transactionId,
                du.itemid,
                du.itemname
				,[promtion_id]				--18
                   ,[promtion_group]			--19
	             ,promtion_ref                --20;
                  ,create_date
      SET @table='R41_document_use';
      SET @Expoprtfilename=@filepath + @table + '\' + @table + @businessDate
                           + '.csv';

      PRINT '666'+@Expoprtfilename

      EXEC report_data.[dbo].Est_export_cvs
        @table,
        @Server,
        @Expoprtfilename;


      --过期优惠券导出
      DELETE R52_coupon_expire

      INSERT INTO [dbo].[R52_coupon_expire]
                  ([member_card_no],
                  reg_compid,
                  reg_comp,
				   reg_storeid,
				  reg_storename,
               --    [sal_comp],
               --    sal_storeid,
              --     sal_storename,
                   [city],
                   [month],
                   [couponType],
                   [end_date],
                   [expire_qty],
                   [expire_je])
      SELECT dc.clubcardid,
	        dc.reg_compid,
            dc.reg_comp,
			 
            dc.reg_storeid,
            dc.reg_storename,
         --   dc.sal_comp,
         --    dc.sal_storeid,
        --     dc.sal_storename,
             dc.city,
             dc.monthly,
             dc.couponType,
             dc.endDate,
             dc.qty,
             dc.pointJe
      FROM   document dc
      WHERE  type = 4

      SET @table='R52_coupon_expire';
      SET @Expoprtfilename=@filepath + @table + '\' + @table + @businessDate
                           + '.csv';

      PRINT @Expoprtfilename

      EXEC report_data.[dbo].Est_export_cvs
        @table,
        @Server,
        @Expoprtfilename;
  END 


GO
