USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[CouponAndPromotionExpiring]    Script Date: 1/19/2022 9:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   procedure [dbo].[CouponAndPromotionExpiring]  
@RetailerId varchar(3)
as 
begin  
declare @businessDate varchar(10) = convert(varchar(10), dateadd(day,6,getdate()),120),
@MatrixMemberId int;
select @MatrixMemberId=MatrixMemberId from report_data..RetailCode_MP r where r.RetailerId=1;
print @businessDate;


 DECLARE @table              VARCHAR(max) ='',
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

      SELECT @FilePath = erc.ExtractLocalPath
      FROM   extractReportConfig erc
      WHERE  erc.MatrixMemberId =1
	 
	  delete  document;

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

 ,type
  ,RetailerId
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
,null --6月度
,N''' + N'积分兑劵'
                        + '''   couponType       --7优惠券类型  
, convert(varchar(10),cld.StartDate,120)    --8发行日期
,convert(varchar(10),cld.EndDate,120)    --9过期日期 
,1  as  qty                            --10数量
--,cpaa.RedeemValue                           --11
--,cpaa.RedeemValue/@bal  redeemValue  ---12-兑换金额
,4 as type 
,Rc.RetailerId

	  from  	 [Loyalty_Shell_1].[dbo].[CRM_LoyaltyDocuments]  cld 
	left join  [Loyalty_Shell_1].[dbo].[CRM_POSLoyaltyDocumentsActivity]  cpda 
	 on  cpda.DocumentInternalKey=cld.DocumentInternalKey and Action=0
	 --inner  join Loyalty_Shell_1.dbo.CRM_POSAccountsActivity  cpaa
 --on cpda.POSTranInternalKey=cpaa.PosTranInternalKey and cpaa.AccountInternalKey=2
  left join store_gs gs on gs.StoreInternalKey=cld.IssueStoreInternalKey and gs.MatrixMemberId=cld.IssueMatrixMemberId
  left join   report_data.[dbo].[v_get_reg_compAndStore]   s   on s.BuyingUnitInternalKey=cpda.BuyingUnitInternalKey
	 -- and  s.MatrixMemberId=cld.IssueMatrixMemberId  --首次注册油站
 left join Loyalty_Shell_1.dbo.CRM_Member cm on cpda.BuyingUnitInternalKey=cm.BuyingUnitInternalKey
  left join RetailCode_MP  rc on rc.MatrixMemberId=cld.IssueMatrixMemberId 
where    convert(varchar(10),cld.EndDate,120)=@businessDate 
  and cld.status=0'
      SET @sql_text=@sql_text_org;
  --    SET @sql_text = Replace(@sql_text, '@MatrixMemberId', @MatrixMemberId);
      SET @sql_text = Replace(@sql_text, '@bal', @bal);
      SET @sql_text = Replace(@sql_text, 'Loyalty_Shell_1', @loyalty_server);
      SET @sql_text = Replace(@sql_text, '@businessDate', '''' + @businessDate + '''');
    		  print @sql_text
      EXEC(@sql_text);



 DELETE R52_coupon_expire

      INSERT INTO [dbo].[R52_coupon_expire]
                  ([member_card_no],
                   [end_date],
                   [expire_qty],
                    RetailerId,
					city     --
				   )
      SELECT dc.clubcardid,
	        @businessDate,
             SUM(dc.qty) ,
			RetailerId
			,'1'
              FROM   document dc
      WHERE  type = 4 
	  group by  dc.clubcardid,RetailerId
	      
   



      INSERT INTO [dbo].[R52_coupon_expire]
                  ([member_card_no],
                   [end_date],
                   [expire_qty],
                    RetailerId,
					city
				   )

select cm.ExternalMemberKey,@businessDate,count(1),@RetailerId,'2'
		   
		 from Loyalty_Shell_1.dbo.CRM_BuyingUnitPromotion cbup
		 left join   Loyalty_Shell_1.dbo.CRM_Member cm on cm.BuyingUnitInternalKey=cbup.BuyingUnitInternalKey
		where 1=1
			--and cbup.MatrixMemberId=@MatrixMemberId
			and  active=1 and convert(varchar(10),cbup.RegistrationEndDate,120)=@businessDate
			GROUP BY cm.ExternalMemberKey

delete   ExpireCouponAndRegPromotion
 insert ExpireCouponAndRegPromotion(RetailerId,ClubCardId,CouponNum,RegPromotion,totalNum,ExpireDate,CreateDate)
   select  r.retailerId,r.member_card_no,sum(case when city='1' then expire_qty else 0 end )  CouponNum
     , sum(case when city='2' then expire_qty else 0 end)  RegPromotion
	 , sum(expire_qty) 
	 ,  end_date
	  ,getdate()  
	   from R52_coupon_expire  r
	  group by r.retailerId,r.member_card_no,end_date
	  			 
			
   SET @table='ExpireCouponAndRegPromotion';
	  declare  @OutPutFileName varchar(30) ='exipringcoupon'+replace(@businessDate,'-','')
	  print @outputfilename
      SET @Expoprtfilename=@filepath + 'ExpireCouponAndRegPromotion' + '\' +'exipringcoupon'+replace(@businessDate,'-','')
                           + '.csv';

      PRINT @Expoprtfilename

      EXEC report_data.[dbo].Est_export_cvs
        @table,
        @Server,
        @Expoprtfilename;





	  end;
GO
