USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[getExpirePoint12Month]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- exec sample: exec getExpirePoint12Month 1
-- =============================================
CREATE  PROCEDURE   [dbo].[getExpirePoint12Month]
	 @MatrixMemberId int
AS
BEGIN
	

declare  @month1 varchar(6),
 @month2 varchar(6),
 @month3 varchar(6),
 @month6 varchar(6),
 @month12 varchar(6),
 @CurrentDate datetime,
 @bal  money = 50 ;
   declare   @table VARCHAR(max) ='promotion_list'
		  ,@Server VARCHAR(max)   ='Loyalty_Shell_uat.dbo.'
		  ,@FilePath NVARCHAR(400)=  'C:\Retalix\HQ\uploadfile_host\a\'  
		  ,@Expoprtfilename nvarchar(300)
		 
select @FilePath=erc.ExtractLocalPath  from extractReportConfig erc where erc.MatrixMemberId=@MatrixMemberId
	print @filepath;


 set @CurrentDate=dateadd(month,0,getdate());
 print @currentdate
 set @month1=convert(varchar(6),@CurrentDate,112)
 set @month3=convert(varchar(6),dateadd(month,2,@CurrentDate),112)
 print '@month3'
 print @month3
 set @month6=convert(varchar(6),dateadd(month,5,@CurrentDate),112)
 print '@month6'+@month6
  set @month12=convert(varchar(6),dateadd(month,11,@CurrentDate),112)
  print '@month12'+@month12
  print @month1
 
 --计算每月积分
 delete     from   [dbo].[R8_2_PointExpiring]
 


INSERT INTO [dbo].[R8_2_PointExpiring]
           ([member_card_no]                  --1
		    , store_code                     --2
           ,[store_name]                     --2.1
		   ,[legal_code]                     --3
           ,[legal_name]                     --4
           ,[city]                           --5
           ,[monthly]                        --6
           ,[item_code1]                     --7              
           ,[item_name1]                     --8
           ,[pointNumber1]                  --9
           ,[pointAmount1]                  --10
           ,[item_code3]                     --11
           ,[item_name3]                    --12
           ,[pointNumber3]                   --13
           ,[pointAmount3]                   --14
           ,[item_code6]                     --15
           ,[item_name6]                    --16
           ,[pointNumber6]                  --17
           ,[pointAmount6]                  --18
           ,[item_code12]                   --19
           ,[item_name12]                   --20
           ,[pointNumber12]                 --21
           ,[pointAmount12]                 --22
           ,[processDate]                   --23
		    ,[reg_compid]                   --24
           ,[reg_comp]                      --25
           ,[reg_storeid]                   --26
           ,[reg_storeName]                 --27
		   )                   
   
 
select  cpt.ClubCardId             --1
         ,case  when  cpt.StoreInternalKey =0 then gs.storeid else store.storeid end storeid                       --2
		,case  when  cpt.StoreInternalKey =0 then gs.StoreName else    store.storename end storeName                     --2.1  
		,case  when  cpt.StoreInternalKey =0 then gs.compid else   store.compid  end compid                           --3
		,case  when  cpt.StoreInternalKey =0 then gs.comp  else  store.comp       end comp                       --4
		,case  when  cpt.StoreInternalKey =0 then gs.city  else  store.city       end city                  --5
		,@month1                        --6
		, case  when  cpt.StoreInternalKey =0 then gs.sku else  store.sku       end sku                         --7
		,case  when  cpt.StoreInternalKey =0 then gs.itemname else  store.itemname       end itemname                   --8
		, sum(pointNumber1)  pointNumber1                --9
		,sum(pointNumber1/@bal) as pointAmount1 --10
, case  when  cpt.StoreInternalKey =0 then gs.sku else  store.sku       end sku                         --7
		,case  when  cpt.StoreInternalKey =0 then gs.itemname else  store.itemname       end itemname                   --8
		, sum(pointNumber3 )                --13
		,sum(pointNumber3/@bal) as pointAmount3 --14
	, case  when  cpt.StoreInternalKey =0 then gs.sku else  store.sku       end sku                         --7
		,case  when  cpt.StoreInternalKey =0 then gs.itemname else  store.itemname       end itemname                   --8
		, sum(pointNumber6)                 --17
		,sum(pointNumber6/@bal) as pointAmount6 --18
		
	, case  when  cpt.StoreInternalKey =0 then gs.sku else  store.sku       end sku                         --7
		,case  when  cpt.StoreInternalKey =0 then gs.itemname else  store.itemname       end itemname                   --8
		, sum(pointNumber12)                  --21
		,sum(pointNumber12/@bal) as pointAmount12 --22
		 
		,getdate()  processdate          --23
		,gs.compid                       --24
		,gs.comp                         --25
		,gs.storeid                      --26
		,gs.StoreName                   --27 
		 from 
( SELECT cpaa.MatrixMemberId 		,cpaa.PosTranInternalKey        
,sum(case when convert(varchar(6),[ExpirationDate],112)<=@month1 then balance  else 0 end) pointNumber1
		,sum(case when convert(varchar(6),[ExpirationDate],112)<=@month3   then balance  else 0 end) pointNumber3
		,sum(case when  convert(varchar(6),[ExpirationDate],112)<=@month6  then balance  else 0 end ) pointNumber6
		,sum(case when  convert(varchar(6),[ExpirationDate],112)<=@month12  then balance  else 0 end ) pointNumber12
		,sum(balance) EarnValue   ,convert(varchar(6),[ExpirationDate],112) month
	    FROM  report_data.dbo.CRM_POSAccountsActivityReward cpaa
         where   --  BuyingUnitInternalKey=6340 and
     balance<>0  and cpaa.ExpirationDate<dateadd(month,13,getdate())  and cpaa.ExpirationDate>dateadd(month,1,getdate())
   	group by     cpaa.[MatrixMemberId],cpaa.PosTranInternalKey,convert(varchar(6),[ExpirationDate],112)
	union all 
	SELECT cpaa.MatrixMemberId 		,cpaa.PosTranInternalKey        
,sum(case when convert(varchar(6),[ExpirationDate],112)<=@month1 then cpard.RedeemValue  else 0 end) pointNumber1
		,0 pointNumber3
		,0 pointNumber6
		,0 pointNumber12
		,0  EarnValue   ,convert(varchar(6),[ExpirationDate],112) month
	    FROM   Loyalty_Shell_uat.dbo.CRM_PosAccountsActivity_RewardLog  cpard  --report_data.dbo.CRM_POSAccountsActivityReward cpaa
	 left join   Loyalty_Shell_uat.dbo.CRM_PosAccountsActivity cpaa on cpaa.PosTranInternalKey=cpard.Earn_PosTranInternalKey
         where   --  BuyingUnitInternalKey=6340 and
		  cpard.RewardStatusId=2 and convert(varchar(6),[ExpirationDate],112)=@month1
      and cpaa.ExpirationDate<dateadd(month,1,getdate())  and cpaa.ExpirationDate>dateadd(month,-2,getdate())
   	group by     cpaa.[MatrixMemberId],cpaa.PosTranInternalKey,convert(varchar(6),[ExpirationDate],112)
	
	
	  )  a
	  left join Loyalty_Shell_uat..CRM_POSTran cpt on  cpt.POSTranInternalKey=a.PosTranInternalKey    and  a.MatrixMemberId=cpt.MatrixMemberId
	left join report_data..store_gs store on store.StoreInternalKey=cpt.StoreInternalKey and cpt.MatrixMemberId=store.MatrixMemberId
	LEFT JOIN  report_data..v_get_reg_compAndStore gs on gs.BuyingUnitInternalKey=cpt.BuyingUnitInternalKey  and cpt.MatrixMemberId=gs.MatrixMemberId
	where a.MatrixMemberId=@MatrixMemberId
	group by 
	cpt.ClubCardId             --1
         ,case  when  cpt.StoreInternalKey =0 then gs.storeid else store.storeid end                       --2
		,case  when  cpt.StoreInternalKey =0 then gs.StoreName else    store.storename end                      --2.1  
		,case  when  cpt.StoreInternalKey =0 then gs.compid else   store.compid  end                             --3
		,case  when  cpt.StoreInternalKey =0 then gs.comp  else  store.comp       end                       --4
		,case  when  cpt.StoreInternalKey =0 then gs.city  else  store.city       end 
		, case  when  cpt.StoreInternalKey =0 then gs.sku else  store.sku       end                         --7
		,case  when  cpt.StoreInternalKey =0 then gs.itemname else  store.itemname       end                   --8

		,gs.compid                       --24
		,gs.comp                         --25
		,gs.storeid                      --26
		,gs.StoreName                   --27 


 set  @table='R8_2_PointExpiring';
set  @Expoprtfilename=@filepath+@table+'\'+@table+@month1+'.csv';
 
exec  report_data.[dbo].est_export_cvs @table,@Server,@Expoprtfilename;	

 
END
GO
