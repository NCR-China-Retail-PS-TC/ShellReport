USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[ModifyDocumentEnddate]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
 declare 
 @CardId varchar(50)='7004900023937303910',
  @BarCode varchar(50)='1331430000003668',
@EndDate varchar(10)='2020-02-28'
exec  ModifyDocumentEnddate @CardId ,@BarCode ,@EndDate
 
*/
--
--2020-03-31 创建 修改document的到期日期。
create  procedure [dbo].[ModifyDocumentEnddate]
@CardId varchar(50),
@BarCode varchar(50),
@EndDate varchar(10)

as
begin


declare  @orgEnddate varchar(10) 
select @orgEnddate=convert(varchar(10),EndDate,120) from   Loyalty_Shell_prod..CRM_LoyaltyDocuments  cld
inner join Loyalty_Shell_prod..CRM_Member cm on cld.IssuedBuyingUnitInternalKey=cm.BuyingUnitInternalKey
where cm.ExternalMemberKey=@CardId and @BarCode=cld.Barcode

if  @@ROWCOUNT=0  
begin 
print 'no Record '
return 
end

insert Crm_ModifyDocumentEnddate 
select cm.ExternalMemberKey,cld.Barcode,cld.EndDate,@EndDate,getdate()    from   Loyalty_Shell_prod..CRM_LoyaltyDocuments  cld
inner join Loyalty_Shell_prod..CRM_Member cm on cld.IssuedBuyingUnitInternalKey=cm.BuyingUnitInternalKey
where cm.ExternalMemberKey=@CardId and @BarCode=cld.Barcode

update  cld set cld.EndDate=@EndDate  from   Loyalty_Shell_prod..CRM_LoyaltyDocuments  cld
inner join Loyalty_Shell_prod..CRM_Member cm on cld.IssuedBuyingUnitInternalKey=cm.BuyingUnitInternalKey
where cm.ExternalMemberKey=@CardId and @BarCode=cld.Barcode

print 'modify  finish'

print  @cardid+'  '+ @orgEndDate+'  '+@EndDate
end
GO
