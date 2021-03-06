USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[GetBecomingExpirePoint]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE  [dbo].[GetBecomingExpirePoint]
	@MatrixMemberId int =1  
AS
BEGIN

print 'begin GetBecomingExpirPoint....'
declare  @month1 varchar(6),
 @month2 varchar(6),
 @month3 varchar(6),
 @CurrentDate date

 set @CurrentDate=dateadd(month,1,getdate());
 print @currentdate
 set @month1=convert(varchar(6),@CurrentDate,112)
 set @month2=convert(varchar(6),dateadd(month,1,@CurrentDate),112)
 set @month3=convert(varchar(6),dateadd(month,2,@CurrentDate),112)
  print @month1
 
 delete  BecomingExpirePointDetail_his where  Calculatedatetime=@CurrentDate
 --计算每月积分
truncate table    BecomingExpirePointDetail
 
insert into BecomingExpirePointDetail(
  [MatrixMemberId]
    
      ,[OneMonthExpirePoint]
     
 
	   ,member_card_no
      ,[Calculatedatetime]
      ,[CalculateBeginDate]
	  ,balance
 )

select @MatrixMemberId
     		,sum(case when month=@month1 then earnvalue  else 0 end) OneMonth
		 ,cc.ClubCardId
		,convert(varchar(10),@CurrentDate,120)
		,convert(varchar(20),getdate(),120)
		,cbua.Balance 
		 from 
( SELECT 
       cpaa.BuyingUnitInternalKey 
        ,MatrixMemberId 
     ,sum(cpaa.balance) EarnValue
	 
	 ,convert(varchar(6),[ExpirationDate],112) month
   FROM  report_data.dbo.CRM_POSAccountsActivityreward cpaa
      where   --  BuyingUnitInternalKey=6340 and
     balance<>0
   and cpaa.ExpirationDate<dateadd(month,3,getdate())  and cpaa.ExpirationDate>getdate()
   	group by  
      [BuyingUnitInternalKey]
      ,[MatrixMemberId]
	  ,convert(varchar(6),[ExpirationDate],112)
	  )  a
	  left join Loyalty_Shell_uat.dbo.CRM_Member cm 
	   on cm.BuyingUnitInternalKey=a.BuyingUnitInternalKey
	   left join  Loyalty_Shell_uat..CRM_BuyingUnitAccountsActivity  cbua 
	      on a.BuyingUnitInternalKey=cbua.BuyingUnitInternalKey 
		  left join Loyalty_Shell_uat..CRM_Clubcard cc on cc.MemberInternalKey=cm.MemberInternalKey
		  where  cbua.AccountInternalKey=2 and cc.MatrixMemberId=@MatrixMemberId
  
 group by a.BuyingUnitInternalKey 
         ,cc.ClubCardId
		,cbua.Balance 
		 having  sum(case when  month=@month1 then earnvalue  else 0 end )>0
	 -- select * from  Loyalty_Shell_1.dbo.CRM_Member


	insert 	BecomingExpirePointDetail_his(
  [MatrixMemberId]
     
      ,[OneMonthExpirePoint]
   
	   ,[ExternalMemberKey]
      ,[Calculatedatetime]
      ,[CalculateBeginDate]
	  ,balance
	  ,id)  
	  select  
  [MatrixMemberId]
      
      ,[OneMonthExpirePoint]
     
	   ,member_card_no
      ,[Calculatedatetime]
      ,[CalculateBeginDate]
	  ,balance
	  ,id
	    from  BecomingExpirePointDetail
	 


  declare   @table VARCHAR(max) ='promotion_list'
		  ,@Server VARCHAR(max)   ='Loyalty_Shell_1.dbo.'
		  ,@FilePath NVARCHAR(400) 
		  ,@Expoprtfilename nvarchar(300)
		 
select @FilePath=erc.ExtractLocalPath  from extractReportConfig erc where erc.MatrixMemberId=@MatrixMemberId
	print @filepath;

 set  @table='BecomingExpirePointDetail';
set  @Expoprtfilename=@filepath+@table+'\'+@table+@month1+'.csv';
 
exec  report_data.[dbo].est_export_cvs @table,@Server,@Expoprtfilename;	
 print 'finished GetBecomingExpirPoint'
END
GO
