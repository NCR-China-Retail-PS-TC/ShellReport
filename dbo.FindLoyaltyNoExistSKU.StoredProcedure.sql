USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[FindLoyaltyNoExistSKU]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
  
  CREATE procedure  [dbo].[FindLoyaltyNoExistSKU]  @matri  int,@CreateDate varchar(10) as 
   
       declare @sql_text  nvarchar(max)
	  ,@sql_text_org nvarchar(max)
	   declare @tableDate_cur varchar(6) 
	   	set @TableDate_cur=SUBSTRING(convert(varchar(10),getdate()-1,112),1,6) --设置年月
 ---查找未下发商品  
  declare @createdDateNextday varchar(10)= dateadd( day,1,convert(date,@createdate,120))	
delete R_LoyaltyNoExistSKU -- where MatrixMemberId = @matri
 set @sql_text_org=N'insert into R_LoyaltyNoExistSKU 
select  distinct  rm.MatrixMemberId                        --16SKU
   ,rm.Name
   , entityid                                           --24促销id
   ,  convert(varchar(20),getdate(),126)
	
   from   
		[ATD_Shell].[dbo].[FO_TranCollection] ftc  (nolock)
		left join RetailCode_MP rm on  ftc.RetailerId=rm.RetailerId
			  inner  join  [ATD_Shell].dbo.FO_TranHeader201704 fth  (nolock)
		  
on ftc.CollectionInternalKey=fth.CollectionInternalKey

  inner join  
    [ATD_Shell].dbo.FO_TranPromotionRewardApportionment201704 ftprd1  (nolock)  
  on ftprd1.TicketInternalKey=fth.TicketInternalKey   and ( (RewardMethodId=1  and RewardId=100) or RewardMethodId  in (3,4,5) )
   
	left join  [report_data].[dbo].item_cat  item    on item.MainItemId=ftprd1.EntityId  and item.MatrixMemberId=rm.MatrixMemberId
	

  where item.MainItemId  is null  and fth.CreatedDate>=convert(date,@createDate,120)   and  fth.CreatedDate<convert(date,@createdDateNextday,120) 
  and  rm.MatrixMemberId=@matri  ';
  set @sql_text=@sql_text_org;
  set @sql_text = replace(@sql_text,'@createDate',''''+@createDate+'''');
	set @sql_text = replace(@sql_text,'@createdDateNextday',''''+@createdDateNextday+'''');

	set @sql_text = replace(@sql_text,'201704',@TableDate_cur);
	set @sql_text = replace(@sql_text,'@matri' ,@matri);
	select @sql_text
	exec(@sql_text);


    

GO
