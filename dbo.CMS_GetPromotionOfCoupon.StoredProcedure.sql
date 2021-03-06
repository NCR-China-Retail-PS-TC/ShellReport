USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[CMS_GetPromotionOfCoupon]    Script Date: 1/19/2022 9:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* =============================================
CR376 异业平台新增接口获取外部券的促销信息
1.	异业平台新增接口，接口用于请求与返回外部券关联的促销信息
2.	Loyalty增加webservice, 通过优惠券ID返回促销信息
3.	第三方平台通过异业平台接口发送查询外部券关联促销的请求给到CMS，请求字段包括Retailer ID 、Coupon ID、Barcode programming ID
4.	CMS将查询请求给到loyalty
5.	Loyalty判断该优惠券是否关联促销，如外部券没有关联促销则返回空或者优惠券的信息；反之则返回外部券关联的促销信息给到CMS
 
 返回
Coupon ID	优惠券实例中对应优惠券的ID；外部券存在则返回该字段
Coupon description	外部券名称
Barcode programming ID	创建外部券的条码后形成的条码编码；外部券存在则返回该字段
Document ID	创建外部券的document后形成的document编码；外部券存在则返回该字段
Document description	Document 名称
Promotion ID	外部券关联的促销ID；只有外部券关联促销才会返回该字段
Promotion description 	外部券关联的促销描述；只有外部券关联促销才会返回该字段
Start time	外部券关联的促销开始时间；只有外部券关联促销才会返回该字段
End time	外部券关联的促销结束时间；只有外部券关联促销才会返回该字段
Active 	外部券关联促销的状态；只有外部券关联促销才会返回该字段
NULL	查询后无外部券信息，返回为空


declare @RetailerID varchar(2)='1'
 	 ,@CouponID varchar(50)='4'
 	 ,@BarcodeId  varchar(50)='4'
 	,@Json nvarchar(max) 
 exec  CMS_GetPromotionOfCoupon @retailerid,@couponId,@BarcodeId,@Json output
 print @json
-- Author:		<Author,,Name>
-- Create date:20210425
-- Description:	<Description,,>
-- =============================================
*/
CREATE  PROCEDURE  [dbo].[CMS_GetPromotionOfCoupon]
	 @RetailerID varchar(2)='2'
	 ,@CouponID varchar(50)='0008'
	 ,@BarcodeId  varchar(50)='136'
	,@Json nvarchar(max) output
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

   

  /* Field Name	Field Description 
Coupon ID	优惠券实例中对应优惠券的ID；外部券存在则返回该字段
Coupon description	外部券名称
Barcode programming ID	创建外部券的条码后形成的条码编码；外部券存在则返回该字段
Document ID	创建外部券的document后形成的document编码；外部券存在则返回该字段
Document description	Document 名称
Promotion ID	外部券关联的促销ID；只有外部券关联促销才会返回该字段
Promotion description 	外部券关联的促销描述；只有外部券关联促销才会返回该字段
Start time	外部券关联的促销开始时间；只有外部券关联促销才会返回该字段
End time	外部券关联的促销结束时间；只有外部券关联促销才会返回该字段
Active 	外部券关联促销的状态；只有外部券关联促销才会返回该字段
NULL	查询后无外部券信息，返回为空

*/
      --优惠券
  

      SET @sql_text_org=N'
	 
select ci.BusinessId  as CouponID
, ci.InstanceDescription
 ,bt.BarcodeId 
 ,ci.DocumentId
 ,bt.Description
  ,ph.PromotionHeaderId	--3
 ,ph.PromotionHeaderDescription
 ,convert(varchar(11),ph.PromotionHeaderStartDate,120)+ph.StartTime StartDate
 ,convert(varchar(11),ph.PromotionHeaderEndDate,120)+ph.EndTime  EndDate
 ,ph.Status

 
  from   	 
    [Promotion_Shell].[dbo].[CouponInstance]  (nolock)ci 
	left join  [Loyalty_Shell_1]..PromotionHeader_PR  (nolock) ph on ph.RequiredCoupon=1 and ph.InstanceInternalKey=ci.InstanceInternalKey	
	    left join RetailCode_MP (nolock)  rc on rc.MatrixMemberId=ph.MatrixMemberId
   left join [Loyalty_Shell_1].[dbo].BarcodeTemplateHeader_PR  (nolock) bt on  bt.MatrixMemberId=ph.MatrixMemberId 
   where   rc.RetailerId=@RetailerID and bt.BarcodeId=@BarcodeId   
    and ci.BusinessId=@CouponID
'
      SET @sql_text=@sql_text_org;
 
    
	      
	  
         SET @sql_text = Replace(@sql_text, 'ATD_Shell', @atd_Server)
        SET @sql_text = Replace(@sql_text, 'Loyalty_Shell_1', @loyalty_server);
   
      	set @sql_text = replace(@sql_text,'@RetailerId' ,''''+@RetailerId+'''');
     	set @sql_text = replace(@sql_text,'@BarcodeId' ,''''+@BarcodeId+'''');
	  	set @sql_text = replace(@sql_text,'@CouponID' ,''''+@CouponID+'''');



 print @json


		


 


     SELECT @sql_text
 



EXEC  [SerializeJSON]   @sql_text,@json output
set @json=N'{"info":'+@json+N'}'
 print @json


  END 

 



GO
