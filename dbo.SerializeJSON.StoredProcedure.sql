USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[SerializeJSON]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE[dbo].[SerializeJSON](
@ParameterSQL AS nVARCHAR(MAX),
@JSON AS NVARCHAR(MAX)  OUTPUT
)
AS
BEGIN
 DECLARE @SQL NVARCHAR(MAX)=''
DECLARE @XMLString nVARCHAR(MAX)
DECLARE @XML XML
DECLARE @Paramlist NVARCHAR(1000)
PRINT '1'
SET @Paramlist = N'@XML XML OUTPUT'
SET @SQL = 'WITH PrepareTable (XMLString)'
SET @SQL = @SQL + 'AS('
SET @SQL = @SQL + @ParameterSQL+ N' FOR XML RAW,TYPE,ELEMENTS'
--SET @SQL = @SQL + @ParameterSQL+ N'FOR XML RAW,TYPE,root('''+'a'+'''),ELEMENTS xsinil'
SET @SQL = @SQL + N')'
PRINT @SQL
SET @SQL = @SQL + N'SELECT @XML=[XMLString]FROM[PrepareTable]'
PRINT @SQL
EXEC sp_executesql @SQL, @Paramlist, @XML=@XML OUTPUT
SET @XMLString=CAST(@XML   AS nvarchar(MAX))
--set @XMLString=substring(@XMLString,len('<a xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">')+1,len(@xmlstring)-57)
--set @XMLString=substring(@XMLString,1,len(@XMLString)-4)

print @xmlString;

DECLARE @Row NVARCHAR(MAX)
DECLARE @RowStart INT
DECLARE @RowEnd INT
DECLARE @FieldStart INT
DECLARE @FieldEnd INT
DECLARE @FieldEnd1 INT
DECLARE @KEY NVARCHAR(MAX)
DECLARE @Value NVARCHAR(MAX)
   
DECLARE @StartRoot NVARCHAR(100);SET @StartRoot=N'<row>'
DECLARE @EndRoot NVARCHAR(100);SET @EndRoot=N'</row>'
DECLARE @StartField NVARCHAR(100);SET @StartField=N'<'
DECLARE @EndField NVARCHAR(100);SET @EndField=N'>'
DECLARE @EndField1 NVARCHAR(100);SET @EndField1=N'/>'
   
SET @RowStart=CharIndex(@StartRoot,@XMLString,0)

SET @JSON=''
WHILE @RowStart>0
BEGIN
    SET @RowStart=@RowStart+Len(@StartRoot)
	
    SET @RowEnd=CharIndex(@EndRoot,@XMLString,@RowStart)
	print '@row'
	--print Len(@RowEnd)
--	print @row
    SET @Row=SubString(@XMLString,@RowStart,@RowEnd-@RowStart)
    SET @JSON=@JSON+'{'
   
    -- for each row
    SET @FieldStart=CharIndex(@StartField,@Row,0)
    WHILE @FieldStart>0
    BEGIN
        -- parse node key
        SET @FieldStart=@FieldStart+Len(@StartField)
        SET @FieldEnd=CharIndex(@EndField,@Row,@FieldStart)
		set @FieldEnd1=CharIndex('/>',@Row,@FieldStart)
		if @FieldEnd-1=@FieldEnd1
	     begin 	
	     SET @KEY=SubString(@Row,@FieldStart,@FieldEnd1-@FieldStart)
		 SET @JSON=@JSON+'"'+@KEY+'":'
		  SET @JSON=@JSON+'"'+'",'
		  SET @FieldStart=@FieldStart+Len(@StartField)+2
        SET @FieldEnd=CharIndex(@EndField,@Row,@FieldStart)
        SET @FieldStart=CharIndex(@StartField,@Row,@FieldEnd)

      end 
	  else 
	   begin 
        SET @KEY=SubString(@Row,@FieldStart,@FieldEnd-@FieldStart)
        SET @JSON=@JSON+'"'+@KEY+'":'
        -- parse node value
        SET @FieldStart=@FieldEnd+1
        SET @FieldEnd=CharIndex('</',@Row,@FieldStart)
        SET @Value=SubString(@Row,@FieldStart,@FieldEnd-@FieldStart)
        SET @JSON=@JSON+'"'+@Value+'",'
        SET @FieldStart=@FieldStart+Len(@StartField)
        SET @FieldEnd=CharIndex(@EndField,@Row,@FieldStart)
        SET @FieldStart=CharIndex(@StartField,@Row,@FieldEnd)
		  end 
    END   
    IF LEN(@JSON)>0SET @JSON=SubString(@JSON,0,LEN(@JSON))
    SET @JSON=@JSON+'},'
    --/ for each row
   
    SET @RowStart=CharIndex(@StartRoot,@XMLString,@RowEnd)

END
IF LEN(@JSON)>0SET @JSON=SubString(@JSON,0,LEN(@JSON))
SET @JSON='['+@JSON+']'

   
END
GO
