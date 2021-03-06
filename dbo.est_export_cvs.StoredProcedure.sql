USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[est_export_cvs]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/**********************************************************************************************************************
 Name:		est_export_cvs

 Description:  	export data  from table into file formatted as csv.

                                                                                			
 Returns:      
 Example:		
	   declare 	
		 @table VARCHAR(max) ='promotion_list'
		  ,@Server VARCHAR(max)   ='Loyalty_Shell_1.dbo.'
		,@FilePath NVARCHAR(100)= 'C:\Retalix\HQ\ExportFile.csv '  
		exec  est_export_cvs  
  	   @table
	  ,@Server	
      ,@FilePath
-- -----------------------------------------------------------------------------------------------------------------------                                                                               			
WHO				WHEN		WHAT
-------------------------------------------------------------------------------------------------------------------------
PeterF		2017/02/19		create

***********************************************************************************************************************/

CREATE  PROCEDURE [dbo].[est_export_cvs]
 @table VARCHAR(max)  
    ,@Server VARCHAR(max)   
    ,@FilePath NVARCHAR(1000) --= 'C:\Retalix\HQ\uploadfile_host\ExportFile.csv ' 
	,@where varchar(400)  =' ' 
AS
BEGIN
declare @tablename nvarchar(50)
        ,@OrderColum nvarchar(50)='O11'

set @server='report_data.dbo.'
set  @tablename=@Server+@table

/*-- 允许配置高级选项  
EXEC sp_configure 'show advanced options', 1  
-- 重新配置  
RECONFIGURE  

-- 启用xp_cmdshell  
EXEC sp_configure 'xp_cmdshell', 0  
--重新配置  
RECONFIGURE  
*/
  DECLARE @Columns  NVARCHAR(max) = '',@Data NVARCHAR(max)=''  
  ,@insert_head nvarchar(max);
       -- SELECT @Columns = @Columns + ',''' + col.name +''''  --   ',N''' + convert(nvarchar(max),EP.value) +''''  --+ '    as   ['+ convert(nvarchar(max),EP.value)+']'   --获取列名（xp_cmdshell导出文件没有列名）  
       SELECT @Columns = @Columns + ',N'''  +case when EP.value is null then col.name else convert(nvarchar(max),EP.value) end  +''''  + '    as  '+ col.name   --获取列名（xp_cmdshell导出文件没有列名）  
	    ,@Data = @Data +  ',Convert(Nvarchar,[' +col.name  +']) '     --将结果集所在的字段更新为nvarchar（避免在列名和数据union的时候类型冲突）  
       	FROM report_data. dbo.syscolumns col
		 LEFT  JOIN sys.extended_properties ep ON col.id = ep.major_id  
                                                      AND col.colid = ep.minor_id  
                                                      AND ep.name = 'MS_Description'  
		 WHERE id = OBJECT_ID(@tablename)  
		 order by colorder;
		
    
	--	set @Columns=SUBSTRING(@Columns,2,LEN(@Columns))
	
	 SELECT @Data  = 'SELECT  2  as '+ @OrderColum+ ' ,' + SUBSTRING(@Data,2,LEN(@Data)) + ' FROM ' + @tablename +@where 
	
	
        SELECT @Columns =' Select  1  as '+ @OrderColum+ ' ,' + SUBSTRING(@Columns,2,LEN(@Columns))  
    
	    --使用xp_cmdshell的bcp命令将数据导出  
	 set @Data=  replace (@Data,'Convert(Nvarchar,[member_card_no])',''''+''''+''''+'''+Convert(Nvarchar,[member_card_no])')
   
		EXEC sp_configure 'xp_cmdshell',1  
        RECONFIGURE  
	if OBJECT_ID('tempdb..##a') is not null
 　　drop table ##a;
 



  DECLARE @cmd1 NVARCHAR(4000) = ' select *  into ##a  from ('+ @Columns+' Union All ' + @Data+') aa'
--print   @cmd1;

exec (@cmd1);  

   declare @sql varchar(1000)
set @sql=''
-- print 'dddd' 
select @sql=@sql+name+',' from tempdb..syscolumns where id=(select id from  tempdb..sysobjects  where name='##a') order by colid
set @sql=substring(@sql,len(@OrderColum)+2,len(@sql)-len(@OrderColum)-2)

--print @sql
 
  -- DECLARE @cmd NVARCHAR(4000) = 'bcp "' + @Columns+' Union All ' + @Data+'" queryout ' + @FilePath + '    -w      -T'  
DECLARE @cmd NVARCHAR(4000) = 'bcp " select '+@sql+'   from ##a  order by '+ @OrderColum+' " queryout ' + @FilePath + '    -w      -T'  
    
--  print @cmd
     
 print 'export'+@table
 print getdate()   
	  
    exec sys.xp_cmdshell @cmd  
	 
        /*   EXEC sp_configure 'xp_cmdshell',0  
        RECONFIGURE  
     */ 
	END 



GO
