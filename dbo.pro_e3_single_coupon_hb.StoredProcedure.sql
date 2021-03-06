USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[pro_e3_single_coupon_hb]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	优惠券使用   20200415 增加折扣分摊
-- =============================================
CREATE  PROCEDURE   [dbo].[pro_e3_single_coupon_hb]
 @createDate varchar(10)='2017-07-27'	
AS
BEGIN
 
       DECLARE @m_etl_date     VARCHAR(10),
              @MatrixMemberId INT=1
			  ,@RetailerId varchar(1);

      SET @MatrixMemberId=1
      SET @m_etl_date=CONVERT(VARCHAR(10), Getdate(), 120);
	  select @RetailerId= r.RetailerId  from  RetailCode_MP R where r.MatrixMemberId=@MatrixMemberId;
-- delete    dhpd   from DS_R1_1_tran_discount dhpd where StoreType= 'DO'  --2020-04-15 delete 
  --插入折扣数据

delete      [e3_single_coupon]  
	   where    [Create_Date]=@createDate
	       and  fb_state in ('0','E')  and   RetailerId=@RetailerId;


  update  drtd  set   drtd.id ='J0303'+drtd.store_code+drtd.create_date+drtd.business_date+ case when   IC.firsttypeCode='10' then drtd.item_code
	                 else drtd.item_cat_mid_cod 
	             end +drtd.taxCode  from  DS_R1_1_tran_discount drtd left join  item_cat  ic on drtd.item_code=ic.MainItemid
		 and ic.MatrixMemberId=@MatrixMemberId


  insert  into   [report_data].[dbo].[e3_single_coupon]
      (  /*   [member_reg_comp_code]  --1
           ,[member_reg_store_code]   --2
           ,[member_reg_store]        --3  */
            [store_code]			  --4
           ,[store_name]			--5
           ,[legal_code]			--6
           ,[legal_name]			--7
           ,[city]					--8
           ,[business_date]			--9
           ,[etl_date]				--10
           ,[etl_time]				--11
           ,[point_type]			--12
           ,[commodity_type]		--13
           ,[commodity_name]		--14
           ,[point_amount]			--15
           ,[point_service_type]	--16
           ,[business_name]			--17
           ,[id]					--18
           ,[fb_state]				--19
		   ,Create_Date
		   ,RetailerId
		   ,TaxCode
		   ,doshare                 --20 
		   ,coshare                 --21
		   ,StoreType
           , dhpd.DoBusinessCode    )
	  select /*drtd.member_reg_comp_code		--1
	        ,drtd.member_reg_store_code		--2
			,drtd.member_reg_store			--3 */
			drtd.store_code				--4
			,drtd.store_name				--5
			,drtd.legal_code				--6
			,drtd.legal_name				--7
			,drtd.city						--8
			,drtd.business_date				--9
			,convert(varchar(10),getdate(),120)  --10
            ,convert(varchar(12),getdate(),114)   --11
	        ,'J09'      --公司发行优惠券 C促销折扣--12
			, case when   ic.firsttypeCode='10' then drtd.item_code
	                      else drtd.item_cat_mid_cod
	          end                               --13
           ,   case when   ic.firsttypeCode='10' then drtd.item_name
	              else drtd.item_cat_mid
		    	end                                --14
				,sum(drtd.discount_amount)        --15
				,'J0303'   --公司发行有效期优惠券   -16
				,N'公司发行有效期优惠券'			--17 
				,  id                       --18
			,'0'   fb_state						--19 
			,create_date
			,@RetailerId
			,drtd.taxCode
			  ,sum(drtd.DOShare) as DOShare           --20
		     ,sum(drtd.COShare) as COShare	       --21
		   ,drtd.StoreType
		   , drtd.DoBusinessCode	                 
	    from DS_R1_1_tran_discount drtd
		left join  item_cat  ic on drtd.item_code=ic.MainItemid
		 and ic.MatrixMemberId=@MatrixMemberId
   where 
	  not  exists    (select id from e3_single_coupon e  where e.id=drtd.id and  fb_state<>'9' and Create_Date =@createDate)

group by 
      	drtd.store_code
			,drtd.store_name
			,drtd.legal_code
			,drtd.legal_name
			,drtd.city
			,drtd.business_date
			,create_date
			, case when   ic.firsttypeCode='10' then drtd.item_code
	                      else drtd.item_cat_mid_cod
	          end                               --13
           ,   case when   ic.firsttypeCode='10' then drtd.item_name
	              else drtd.item_cat_mid
		    	end                                --13.1
					, id
				 ,drtd.taxCode	 
				 ,drtd.StoreType	
	 ,drtd.DoBusinessCode
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
