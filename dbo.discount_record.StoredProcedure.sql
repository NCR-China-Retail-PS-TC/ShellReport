USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[discount_record]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE  [dbo].[discount_record]
AS
BEGIN
select dsd.加油站编码,dsd.营业日期,dsd.促销商品, dd.促销ID,aa.促销描述,aa.促销类型描述,aa.[  促销类型],dd.[          数量],dd.[       零售金额],dd.[       实际金额] 

 from  DiscountSuccessDetail  dsd 
left join  DiscountDetail dd on dsd.营业日期=dd.[   营业日期] and dsd.促销商品=dd.商品编码 and dsd.加油站编码=dd.[  油站编码] 
left join  ( select distinct 促销ID,dd.促销描述,dd.促销类型描述,dd.[  促销类型] from DiscountDetail dd where rtrim(ltrim(dd.促销类型描述 ))<>''  ) aa
 on aa.促销ID=dd.促销ID
 where   dd.来源='BOS'  --and  dsd.加油站编码='2002' and dsd.促销商品='105740' and '2019.09.05'=dd.[   营业日期]
order by   dsd.加油站编码,dsd.营业日期,dsd.促销商品
END
GO
