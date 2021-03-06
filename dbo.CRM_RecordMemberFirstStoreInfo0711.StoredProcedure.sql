USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[CRM_RecordMemberFirstStoreInfo0711]    Script Date: 1/19/2022 9:01:17 AM ******/
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
CREATE PROCEDURE [dbo].[CRM_RecordMemberFirstStoreInfo0711] 
	
AS
BEGIN
	 
	 declare @datatime varchar(10);
	 declare @datatime1 varchar(10);
	 set @datatime=convert(varchar(10),getdate()-1,120)
	  set @datatime1=convert(varchar(10),getdate()+1,120)
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
select  distinct  cm.MemberInternalKey, cpt.StoreInternalKey, 0 isHomeStore , '2'  as StoreTypeId,cpt.MatrixMemberId, cpt.StartDateTime
	      , '0000' UpdatedBy 	FROM
			loyalty_shell_prod.dbo.CRM_POSTran cpt,loyalty_shell_prod.dbo.CRM_Member cm,loyalty_shell_prod.dbo.Store_MP store
		WHERE
		  cpt.MatrixMemberId=store.MatrixMemberId  and cpt.StoreInternalKey=store.StoreInternalKey
		   and cpt.BuyingUnitInternalKey=cm.BuyingUnitInternalKey
		   and cpt.IsTransactionVoid in (0,1)
		   and  convert(varchar(10),cpt.CreatedAt,120)<@datatime1
		   and convert(varchar(10),cpt.CreatedAt,120)>=@datatime
		   and not   exists  (
		   select 1  from  	report_data.dbo.CRM_MemberStoreAssign_shell MSA
		   where msa.MatrixMemberId=cpt.MatrixMemberId --and msa.StoreInternalKey=cpt.StoreInternalKey
		         and msa.StoreTypeId='2' and cm.MemberInternalKey = msa.MemberInternalKey )
				-- and MemberInternalKey=6415
				 ) a ) b where b.Rownumber=1
	END


	 
 
 


GO
