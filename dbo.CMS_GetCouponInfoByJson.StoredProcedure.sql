USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[CMS_GetCouponInfoByJson]    Script Date: 1/19/2022 9:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <2019-12-18
-- Description: CMS调用接口查询洗车券，返回哪种类型的券，由参数券类型确定
---券类型，默认1
--parameter 会员loyaltyid，RetailerID（如果0表示返回所有Retailer下的券），CouponType券类型 1 (2000 洗车券 )，State券状态( 1  unused 2 used  3 expired  )
/*declare @RetailerID  varchar(10)='1'
	,@ClubCardId  varchar(50)='7004900092862153410'
	,@CouponType   varchar(1)='1'
	,@State     varchar(1)='1'
    ,@json  nvarchar(max) 
 exec  CMS_GetCouponInfoByJson @RetailerID,@ClubCardId,@CouponType,@State,@json  output  
 print @json 
 */
-- =============================================
CREATE  PROCEDURE  [dbo].[CMS_GetCouponInfoByJson]
	@RetailerID  varchar(10)
	,@ClubCardId  varchar(50)
	,@CouponType   varchar(1)
	,@State     varchar(1)
    ,@json  nvarchar(max) output
AS
BEGIN
  set transaction isolation  level read uncommitted;
    declare @sql nvarchar(max)
	,@PreString varchar(200) ;

   declare  @MatrixMemberId varchar(2) ;
   select   @MatrixMemberId=MatrixMemberId from RetailCode_MP rc  where rc.RetailerId=@RetailerID
     if @RetailerID='0'
      set @MatrixMemberId='%';

	  if @CouponType='1' 
	  set @PreString='2000%'

  select  cm.ExternalMemberKey                        
         ,@RetailerId  as  RetailerID    
		  ,cld.Barcode                                
          ,ci.InstanceDescription           
          ,convert( numeric,SUBSTRING(cld.Barcode,5,3) ) as balance  
        , CONVERT(VARCHAR(10), CPDA.PosDateTime,120)  IssueDate              --8
   ,case when cld.Status=1 then  2  when  cld.Status=0 and cld.EndDate<convert(varchar(10),getdate(),120)  then  3 
    when   cld.Status=0 and cld.EndDate>=convert(varchar(10),getdate(),120)  then  1  else  9    END   state--10  
                                  
  ,case when cld.Status=1 then  N'已使用' when  cld.Status=0 and cld.EndDate<getdate()  then N'已过期'
  when   cld.Status=0 and cld.EndDate>=getdate()  then N'未使用' else 'sdsd'    END   StateName--10  
  ,CONVERT(VARCHAR(10),cpda1.PosDateTime,120) UsingDate  --11
  ,CONVERT(VARCHAR(10),cld.EndDate,120)  ExpireDate  --12
   
  into #Coupon 
  
  from  	 Loyalty_Shell_prod.[dbo].[CRM_LoyaltyDocuments]  cld 
    left join [Promotion_Shell].[dbo].[CouponInstance] ci on cld.DocumentId=ci.DocumentId
		left join Loyalty_Shell_prod.[dbo].[CRM_POSLoyaltyDocumentsActivity]  cpda 
	 on  cpda.DocumentInternalKey=cld.DocumentInternalKey and Action=0
 	left join Loyalty_Shell_prod.[dbo].[CRM_POSLoyaltyDocumentsActivity]  cpda1 
	 on  cpda1.DocumentInternalKey=cld.DocumentInternalKey and cpda1.Action=1

  left join Loyalty_Shell_prod.dbo.CRM_Member cm on cld.IssuedBuyingUnitInternalKey=cm.BuyingUnitInternalKey
   where  cld.issueMatrixMemberId like @MatrixMemberId 
and cm.ExternalMemberKey=@ClubCardId and 
    case when cld.Status=1 then  2  when  cld.Status=0 and cld.EndDate<convert(varchar(10),getdate(),120)  then  3 
    when   cld.Status=0 and cld.EndDate>= convert(varchar(10),getdate(),120)  then  1  else  9    END=@State
	and cld.Barcode like @PreString
 --select  *  from #Coupon  
 set  @sql='select *  from  #Coupon order by balance   desc ,ExpireDate    desc '

EXEC report_data..[SerializeJSON]   @sql,@json output
set @json=N'{"CouponInfo":'+@json+N'}'
 --print @json

END
GO
