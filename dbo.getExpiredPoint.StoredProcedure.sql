USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[getExpiredPoint]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Zhengyuepo
-- Create date: 2019.03.01
-- Description:	1.	???????R8_1
-- exec sample: exec getExpiredPoint  1
-- =============================================
CREATE  PROCEDURE   [dbo].[getExpiredPoint]
	 @MatrixMemberId int,@date varchar(10)
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
		  ,@Server VARCHAR(max)   ='Loyalty_Shell_prod.dbo.'
		  ,@FilePath NVARCHAR(400)=  'C:\Retalix\HQ\uploadfile_host\a\'  
		  ,@Expoprtfilename nvarchar(300)
		 
select @FilePath=erc.ExtractLocalPath  from extractReportConfig erc where erc.MatrixMemberId=@MatrixMemberId
	print @filepath;

  set @CurrentDate=@date;
 print @currentdate
 set @month1=convert(varchar(6),@CurrentDate,112)
 print @month1


 --??????
 delete     from   [dbo].[R8_1_PointExpired]
 


INSERT INTO [dbo].[R8_1_PointExpired]
           ([member_card_no]                  --1
		    , store_code                     --2
           ,[store_name]                     --3
		   ,[legal_code]                     --4
           ,[legal_name]                     --5
           ,[city]                           --6
           ,[monthly]                        --7
           ,[item_code1]                     --8              
           ,[item_name1]                     --9
           ,[pointNumber1]                  --10
           ,[pointAmount1]                  --11
           ,[processDate]                   --12
		    ,[reg_compid]                   --13
           ,[reg_comp]                      --14
           ,[reg_storeid]                   --15
           ,[reg_storeName]                 --16
		   ,tranid                         --17
		   ,posid  
		   )                   
   
 
select  cpt.ClubCardId             --1
         ,case  when  cpt.StoreInternalKey =0 then gs.storeid else store.storeid end storeid                       --2
		,case  when  cpt.StoreInternalKey =0 then gs.StoreName else    store.storename end storeName                     --3  
		,case  when  cpt.StoreInternalKey =0 then gs.compid else   store.compid  end compid                           --4
		,case  when  cpt.StoreInternalKey =0 then gs.comp  else  store.comp       end comp                       --5
		,case  when  cpt.StoreInternalKey =0 then gs.city  else  store.city       end city                  --6
		,@month1                        --7
		, case  when  cpt.StoreInternalKey =0 then gs.sku else  store.sku       end sku                         --8
		,case  when  cpt.StoreInternalKey =0 then gs.itemname else  store.itemname       end itemname                   --9
		, sum(cpard.RedeemValue)  pointNumber1                --10
		,sum(cpard.RedeemValue/@bal) as pointAmount1 --11
 
		,getdate()  processdate          --12
		,gs.compid                       --13
		,gs.comp                         --14
		,gs.storeid                      --15
		,gs.StoreName                   --16
		,cpt.TranId                 ---17
		,cpt.PosId                   --18
		 from 
  Loyalty_Shell_UAT.dbo.CRM_PosAccountsActivity_RewardLog  cpard
	  left join Loyalty_Shell_UAT.dbo.CRM_POSTran cpt  on cpard.Earn_PosTranInternalKey=cpt.POSTranInternalKey
	   left join   Loyalty_Shell_UAT.dbo.CRM_PosAccountsActivity cpaa on cpaa.PosTranInternalKey=cpard.Earn_PosTranInternalKey
	      and cpaa.AccountInternalKey=2
		left join report_data..store_gs store on store.StoreInternalKey=cpt.StoreInternalKey and cpt.MatrixMemberId=store.MatrixMemberId
    	LEFT JOIN    report_data..v_get_reg_compAndStore gs on gs.BuyingUnitInternalKey=cpt.BuyingUnitInternalKey  and cpt.MatrixMemberId=gs.MatrixMemberId
	where 	 cpard.RewardStatusId=2 and convert(varchar(7),cpard.ProcessDate,120)=convert(varchar(7),@currentdate,120)  
		and gs.storeid
		  +case when  store.storeid is null then gs.storeid else store.storeid end      is not null 
		   and gs.MatrixMemberId= cpaa.MatrixMemberId and cpt.MatrixMemberId=@MatrixMemberId and cpt.MatrixMemberId= cpaa.MatrixMemberId
   

	group by
	cpt.ClubCardId
	  ,gs.compid                        
		,gs.comp                         
		,gs.storeid                      
		,gs.StoreName                   
	      ,case  when  cpt.StoreInternalKey =0 then gs.storeid else store.storeid end                       --2
		,case  when  cpt.StoreInternalKey =0 then gs.StoreName else    store.storename end                      --3  
		,case  when  cpt.StoreInternalKey =0 then gs.compid else   store.compid  end                            --4
		,case  when  cpt.StoreInternalKey =0 then gs.comp  else  store.comp       end                         --5
		,case  when  cpt.StoreInternalKey =0 then gs.city  else  store.city       end                  --6
		 
		, case  when  cpt.StoreInternalKey =0 then gs.sku else  store.sku       end                          --8
		,case  when  cpt.StoreInternalKey =0 then gs.itemname else  store.itemname       end                    --9
		,cpt.TranId                 ---17
		,cpt.PosId                   --18
 set  @table='R8_1_PointExpired';
set  @Expoprtfilename=@filepath+@table+'\'+@table+@month1+'.csv';
 
exec  report_data.[dbo].est_export_cvs @table,@Server,@Expoprtfilename;	


	--Reconciliation
	declare @retailerID char(1) 
	select @RetailerId= r.RetailerId  from  RetailCode_MP R where r.MatrixMemberId=@MatrixMemberId;

	delete report_data..ReconciliationR2ERP 
	where RetailerId = @RetailerId 
	and DataType in ('R8_1')
	and CreatedAt = @month1;

	insert into report_data..ReconciliationR2ERP
	(	RetailerId,
		DataType,
		CreatedAt,
		BusinessDate,
		Point,
		StoreType
	)
	select @RetailerId,'R8_1',r.monthly,r.monthly,sum(r.pointNumber1),s.StoreType
	from report_data..R8_1_PointExpired r
	left join report_data..store_gs s 
	on r.store_code = s.storeid 
	and s.MatrixMemberId = @MatrixMemberId
	group by r.monthly,s.StoreType

 
END

GO
