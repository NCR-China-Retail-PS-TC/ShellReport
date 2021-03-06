USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[P_CRM_GrowthValue]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
会员成长值初始化的要求，如有错误请更正


1.	计算时间范围：2021/1/11-2021/3/1
2.	计算规则/需求：
•	将交易中购买的柴油1升计算为5成长值、汽油92# 1升10成长值、汽油95# 1升15成长值、汽油98# 1升20成长值、非油品1元5成长值，计算后将会员的成长值存入指定账户
•	可按照日期范围与JV大区分组来筛选会员成长值
•	成长值计算好后，以CSV的形式给到喂车
declare 
@retailerId varchar(10)='2',
@begindate varchar(20)='2021-01-01',
@enddate varchar(20)='2021-01-01 23:59:59'


   exec P_CRM_GrowthValue
@retailerId  ,
@begindate ,
@enddate  

*/

CREATE procedure  [dbo].[P_CRM_GrowthValue]
@retailerId varchar(10),
@begindate varchar(20),
@enddate varchar(20)
AS 
declare @OtherValue int= 5


   DECLARE @table           VARCHAR(max) ='promotion_list',
              @Server          VARCHAR(max) ='Loyalty_Shell_1.dbo.',
              @FilePath        NVARCHAR(400)= 'C:\Retalix\HQ\uploadfile_host\a\',
              @Expoprtfilename NVARCHAR(300),
              @bal             FLOAT =50.00; --per 50  point  for 1 rmb   201801102
      DECLARE @curMonth  VARCHAR(6),
              @tableDate_pre  VARCHAR(6),
              @atd_Server     NVARCHAR(max) ='ATD_Shell',
              @ServerHost     NVARCHAR(max)='HOST_Shell_1',
              @loyalty_server VARCHAR(max)='Loyalty_Shell_1',
			  @Promotion_server varchar(100)='promotion_server',
              @sql_text       NVARCHAR(max),
              @sql    NVARCHAR(max),
              @sql_text_org1  NVARCHAR(max),
			  @matrixMemberId int;
		
		set @curMonth=substring(@begindate,1,4)+substring(@begindate,6,2)
			  
      SELECT @atd_Server = c.paraValue0
      FROM   dbo.param_config c
      WHERE  c.paraName = 'atd_Server';
     SELECT  @Promotion_server = c.paraValue0
      FROM   dbo.param_config c
      WHERE  c.paraName = 'promotion_server';

      SELECT @ServerHost = c.paraValue0
      FROM   dbo.param_config c
      WHERE  c.paraName = 'ServerHost';

      SELECT @loyalty_server = c.paraValue0
      FROM   dbo.param_config c
      WHERE  c.paraName = 'loyalty_server';
	  select  @matrixMemberId=MatrixMemberId from report_data..RetailCode_MP r where r.RetailerId=@retailerId
	  	select @FilePath=erc.ExtractLocalPath  from extractReportConfig erc where erc.MatrixMemberId=@MatrixMemberId
select @OtherValue=GrowthValue   from
 CRM_GrowthValue  
 where ItemId='9999' and MatrixMemberdId=@matrixmemberId;
 truncate table  CRM_MemberGrowthValueDetail
 set   @sql_text='
INSERT   CRM_MemberGrowthValueDetail
(CardID	,
RetailerId	,
StoreId	,
PosID	,
TransID	,
BusinessDate	,
StartDateTime	,
TransactionVoid	,
ID	,
EarnValue	,
RdmValue	

)
select ftcc.CardId,
ftc.RetailerId,
ftc.StoreId
,ftc.TillId
,fth.TranId
,convert(varchar(10),ftc.BusinessDate,120)
,convert(varchar(10),fth.CreatedDate,120)
,iif( sum( fts.qty)>0 ,1,0)
,isnull(cgv.AccountId,'''+'303'+''')  
  
,iif(sum(fts.qty)>0,  case   when cgv.itemid is null then round(sum(fts.amount),0,1)*5  else round(sum(fts.qty),0,1)*cgv.GrowthValue  end ,0)  as Earvalue 
,iif(sum(fts.qty)<0,  case   when cgv.itemid is null then round(sum(fts.amount),0,1)*5  else round(sum(fts.qty),0,1)*cgv.GrowthValue  end ,0)  as Earvalue 

   from ATD_Shell..FO_TranCard202101  ftcc 
left join ATD_Shell..FO_TranHeader202101 fth on  ftcc.TicketInternalKey=fth.TicketInternalKey
left join ATD_Shell..FO_TranCollection ftc on ftc.CollectionInternalKey=fth.CollectionInternalKey
left join report_data..RetailCode_MP rc on rc.RetailerId=ftc.RetailerId
left join (select  fts.TicketInternalKey,fts.ItemId , fts.amount-isnull(ftpra.RewardValue,0) as amount,fts.qty
             from  ( select  fts.TicketInternalKey,fts.ItemId ,sum(fts.Qty) as qty,sum(fts.Amount) as amount  from  ATD_Shell..fo_transale202101 fts
                                     GROUP BY  FTS.TicketInternalKey,fts.ItemId)  fts
                         left join  ( select   ftpra.EntityId,sum(ftpra.RewardValue) as RewardValue,TicketInternalKey   from   ATD_Shell..FO_TranPromotionRewardApportionment202101   ftpra 
                     where ftpra.RewardMethodId=4 group by  ftpra.EntityId,ftpra.TicketInternalKey) 	    ftpra 
					on ftpra.TicketInternalKey=fts.TicketInternalKey and ftpra.EntityId=fts.ItemId  ) 
	fts on ftcc.TicketInternalKey=fts.TicketInternalKey 
left join Loyalty_Shell_1..CRM_Clubcard cc on cc.ClubCardId=ftcc.CardId and cc.MatrixMemberId=rc.MatrixMemberId
left join report_data..CRM_GrowthValue cgv  on cgv.MatrixMemberdId=rc.RetailerId and cgv.ItemId=fts.ItemId
where rc.RetailerId=@retailerid  and fth.CreatedDate>@BeginDate and fth.CreatedDate<=@EndDate
group by ftcc.CardId,
ftc.RetailerId,
ftc.StoreId
,ftc.TillId
,fth.TranId
,convert(varchar(10),ftc.BusinessDate,120)
,convert(varchar(10),fth.CreatedDate,120)
,iif( fts.qty>0 ,1,0)
,isnull(cgv.AccountId,'''+'303'+''')  
,cgv.itemid
,cgv.GrowthValue
having  iif(sum(fts.qty)>0,  case   when cgv.itemid is null then round(sum(fts.amount),0,1)*5  else round(sum(fts.qty),0,1)*cgv.GrowthValue  end ,0)  
+iif(sum(fts.qty)<0,  case   when cgv.itemid is null then round(sum(fts.amount),0,1)*5  else round(sum(fts.qty),0,1)*cgv.GrowthValue  end ,0)   >0

'
     SET @sql=@sql_text;
         
		    SET @sql = Replace(@sql, 'ATD_Shell', @atd_Server);
            SET @sql = Replace(@sql, 'Loyalty_Shell_1', @loyalty_server);
          SET @sql = Replace(@Sql, '202101', @curMonth);
            SET @sql = Replace(@sql, '@BeginDate', '''' + @BeginDate + '''');
            SET @sql = Replace(@sql, '@EndDate', '''' + @EndDate + '''');
            print @sql   SET @sql = Replace(@sql, '@retailerid', '''' + @retailerid + '''');
		    SET @sql = Replace(@sql, '@OtherValue',   @OtherValue  );
			   
        
			 SET @sql = Replace(@Sql, 'Promotion_Shell', @Promotion_server);
			    
			select @sql
			print @sql
			exec (@sql)
			    set  @table='CRM_MemberGrowthValueDetail';
      set  @Expoprtfilename=@filepath+@table+'\'+@table+@BeginDate+'.csv';
	   print @Expoprtfilename  
      exec  report_data.[dbo].est_export_cvs @table,@Server,@Expoprtfilename,'';	
			      
			      

GO
