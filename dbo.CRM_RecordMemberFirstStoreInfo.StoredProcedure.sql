USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[CRM_RecordMemberFirstStoreInfo]    Script Date: 1/19/2022 9:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:  记录会员的第一笔交易日期,及门店.
--	如果中间启用该程序需要对把CRM_MemberStoreAssign 中的数据 插入到
-- CRM_MemberStoreAssign_shell 表进行,并更新update 日期. 
-- =============================================
CREATE PROCEDURE [dbo].[CRM_RecordMemberFirstStoreInfo] 
	
AS
BEGIN
	 
 /* declare @datatime varchar(10);
	set @datatime=convert(varchar(10),getdate()-1,120)
	--set @datatime='2017-07-25'
--	set @datatime1='2017-06-24'
	 		insert into  [CRM_MemberStoreAssign_shell]
							(
							MemberInternalKey,
							StoreInternalKey,
							isHomeStore,
							StoreTypeId,
							MatrixMemberId,
							UpdatedDate,
							UpdatedBy
							)
	
	select    MemberInternalKey, StoreInternalKey,  isHomeStore ,  StoreTypeId,MatrixMemberId, StartDateTime
	      ,   UpdatedBy 
		from    (select ROW_NUMBER() over(partition by  memberinternalkey   order by startDatetime) Rownumber ,* from (
select  distinct  vsc.MemberInternalKey, cpt.StoreInternalKey, 0 isHomeStore , '2'  as StoreTypeId,cpt.MatrixMemberId, cpt.StartDateTime
	      , '0000' UpdatedBy  
		  	FROM
			Loyalty_Shell_Prod.dbo.CRM_POSTran cpt    
			left join report_data.dbo.v_segment_comp vsc  on cpt.BuyingUnitInternalKey=vsc.BuyingUnitInternalKey 
			     left join  report_data.dbo.store_gs gs on cpt.MatrixMemberId=gs.MatrixMemberId  and cpt.StoreInternalKey=gs.StoreInternalKey
	         
		WHERE   cpt.IsTransactionVoid in (0,1)
		   and gs.compID=vsc.R_compid
		   and  convert(varchar(10),cpt.CreatedAt,120)=@datatime

		   and not   exists  (
		   select 1  from  	report_data.dbo.CRM_MemberStoreAssign_shell MSA
		   where msa.MatrixMemberId=cpt.MatrixMemberId --and msa.StoreInternalKey=cpt.StoreInternalKey
		         and msa.StoreTypeId='2' and vsc.MemberInternalKey = msa.MemberInternalKey )
				-- and MemberInternalKey=6415
				 ) a ) b where b.Rownumber=1







	END
*/
	
 

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:  记录会员的第一笔交易日期,及门店.
--	如果中间启用该程序需要对把CRM_MemberStoreAssign 中的数据 插入到
-- CRM_MemberStoreAssign_shell 表进行,并更新update 日期. 
--20191205  修改首次发生非DO站的消费，才作为注册油站 
-- =============================================

	 
 declare @datatime DATE;
	set @datatime=getdate()-9
	--set @datatime='2017-07-25'
--	set @datatime1='2017-06-24'
	 		insert into  [CRM_MemberStoreAssign_shell]
							(
							MemberInternalKey,
							StoreInternalKey,
							isHomeStore,
							StoreTypeId,
							MatrixMemberId,
							UpdatedDate,
							UpdatedBy
							)
	
	select    MemberInternalKey, StoreInternalKey,  isHomeStore ,  StoreTypeId,MatrixMemberId, StartDateTime
	      ,   UpdatedBy 
		from    (select ROW_NUMBER() over(partition by  memberinternalkey   order by startDatetime) Rownumber ,* from (
select  distinct  vsc.MemberInternalKey, cpt.StoreInternalKey, 0 isHomeStore , '2'  as StoreTypeId,cpt.MatrixMemberId, cpt.StartDateTime
	      , '0000' UpdatedBy  
		  	FROM
			Loyalty_Shell_UAT.dbo.CRM_POSTran cpt    
			left join report_data.dbo.v_segment_comp vsc  on cpt.BuyingUnitInternalKey=vsc.BuyingUnitInternalKey 
			     left join  report_data.dbo.store_gs gs on cpt.MatrixMemberId=gs.MatrixMemberId  and cpt.StoreInternalKey=gs.StoreInternalKey
	         
		WHERE   cpt.IsTransactionVoid in (0,1)
		   and gs.compID=vsc.R_compid
		   and  cpt.CreatedAt>@datatime
		   and  (  --cpt.MatrixMemberId=1  and 
		   
		    gs.StoreType<>'DO' or gs.StoreType is null  ) -- 修改首次发生非DO站的消费
		   and not   exists  (
		   select 1  from  	report_data.dbo.CRM_MemberStoreAssign_shell MSA
		   where msa.MatrixMemberId=cpt.MatrixMemberId --and msa.StoreInternalKey=cpt.StoreInternalKey
		         and msa.StoreTypeId='2' and vsc.MemberInternalKey = msa.MemberInternalKey )
				-- and MemberInternalKey=6415
				 ) a ) b where b.Rownumber=1
	END

	
 
   


   


GO
