USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[pro_e3_single_coupon_sx]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description: 增加DO站折扣分摊比例，在单法律实体优惠券中传输到ERP中
--20200401 deploy
--20200804CR312  对于DOCO站的折扣数据油品和非油都通过单法律实体优惠券接口上传ERP
    积分类型：J13，业务类型名称：DO促销折扣

-- =============================================
*/
CREATE PROCEDURE   [dbo].[pro_e3_single_coupon_sx]
 @createDate varchar(10)='2017-07-27'	
AS
BEGIN
 
       DECLARE @m_etl_date     VARCHAR(10),
              @MatrixMemberId INT=2
			  ,@RetailerId varchar(1)='2';
     
      SET @m_etl_date=CONVERT(VARCHAR(10), Getdate(), 120);
	 	 select @MatrixMemberId=MatrixMemberId,@RetailerId=RetailerId
		  from  RetailCode_MP rcmp     where rcmp.RetailValue='2'   ;   ----sx RetailerId   is 2

	   -- 删除非do站数据
 -- delete    dhpd   from ds_h1_PromotionDiscount dhpd where StoreType<>'DO'  or StoreType is null 

 ---壳牌陕西JV希望Loyalty控制跨月促销折扣数据不传输到ERP。
     if substring(@createDate,9,2)>'02' 
  delete ds_h1_PromotionDiscount  where substring(business_date,1,7)<SUBSTRING(@createDate,1,7)
   



  --插入折扣数据

  	delete      [e3_single_coupon]  
	   where    [Create_Date]=@createDate
	       and  fb_state in ('0','E')  and   RetailerId=@RetailerId;


  update  drtd  set   drtd.id ='J0303'+drtd.store_code+convert(varchar(8),drtd.create_date,12)+convert(varchar(8),convert(date,drtd.business_date,120),12)+ case when   IC.firsttypeCode='10' then drtd.itemCode
	                 else drtd.item_cat_mid_cod 
	             end +drtd.taxCode  
				  from  ds_h1_PromotionDiscount drtd left join  item_cat  ic on drtd.itemCode=ic.MainItemid
		 and ic.MatrixMemberId=@MatrixMemberId


  insert  into   [report_data].[dbo].[e3_single_coupon]
      (  
		     RetailerId              --1
            ,[store_code]			 --2
           ,[store_name]			--3
           ,[legal_code]			--4
           ,[legal_name]			--5
           ,[city]					--6
           ,[business_date]			--7
           ,[etl_date]				--8
           ,[etl_time]				--9
           ,[point_type]			--10
           ,[commodity_type]		--11
           ,[commodity_name]		--12
           ,[point_amount]			--13
           ,[point_service_type]	--14
           ,[business_name]			--15
           ,[id]					--16
           ,[fb_state]				--17
		   ,Create_Date             --18
		  
		   ,TaxCode                 --19
           ,doshare                 --20 
		   ,coshare                 --21
		   ,StoreType
		   ,DoBusinessCode
		   )

  select     dhpd.RetailerId                --1
			,dhpd.store_code				--2
			,dhpd.store_name				--3
			,LegalCode                      --4
			,LegalName                      --5 
			, '' as city                    --6
			,dhpd.business_date				--7
			 ,convert(varchar(10),getdate(),120)  --8
             ,convert(varchar(12),getdate(),114)   --9
			 ,'J13'  as [point_type]           --10 
			 			
			, case when   ic.firsttypeCode='10' then dhpd.itemCode
	                      else dhpd.item_cat_mid_cod
	          end            [commodity_type]                   --11
           ,   case when   ic.firsttypeCode='10' then dhpd.item_name
	              else dhpd.item_cat_mid
		    	end           [commodity_name]                     --12
			,SUM(dhpd.SaleAmount-dhpd.ReceiveAmount) AS point_amount --13
			,'J13'                                     --14
			,N'DO促销折扣'                                               --15
	     ,          id                       --16
		   ,'0'   fb_state						--17
		   ,convert(varchar(10),create_date,120)   --18
		   ,dhpd.TaxCode                           --19
		   ,sum(dhpd.DOShare) as DOShare           --20
		   ,sum(dhpd.COShare) as COShare	       --21
		   ,dhpd.StoreType
		   , DoBusinessCode                 
	    from ds_h1_PromotionDiscount dhpd
			left join  item_cat  ic on dhpd.itemCode=ic.MainItemid
		   and ic.MatrixMemberId=@MatrixMemberId
		   where 
	 	  		( StoreType='DO' or  StoreType='DOCO' )   --20200804 对于DOCO站的折扣数据油品和非油都通过单法律实体优惠券接口上传ERP
				  and 
	 not exists	  (select 1 from e3_single_coupon where fb_state<>'9'   
	 and id=dhpd.id
					   )

group by 
      	     dhpd.RetailerId
			,dhpd.store_code				--4
			,dhpd.store_name				--5
			,LegalCode
			,LegalName
		
			,dhpd.business_date				--9
			
			, case when   ic.firsttypeCode='10' then dhpd.itemCode
	                      else dhpd.item_cat_mid_cod
	          end          
           ,   case when   ic.firsttypeCode='10' then dhpd.item_name
	              else dhpd.item_cat_mid
		    	end         
			, id
			,convert(varchar(10),create_date,120)
			,dhpd.TaxCode
			,dhpd.StoreType
			,DoBusinessCode


	



delete  from e3_single_coupon where fb_state='9' and Create_Date =@createDate and RetailerId=@RetailerId; 
--Reconciliation
	delete report_data..ReconciliationR2ERP 
	where RetailerId = @RetailerId 
	and DataType in ('E3')
	and CreatedAt = @CreateDate;


	insert into report_data..ReconciliationR2ERP
	(	
		RetailerId,
		DataType,
		CreatedAt,
		BusinessDate,
		Point,
		StoreType
	)
	select @RetailerId,'E3',e.Create_date,e.business_date,sum(e.point_amount),store.StoreType
	from e3_single_coupon e
	left join [report_data].[dbo].store_gs store on e.store_code = store.storeid
	where e.RetailerId = @RetailerId 
	and e.Create_date = @createDate
	group by e.Create_date,e.business_date,store.StoreType
END

GO
