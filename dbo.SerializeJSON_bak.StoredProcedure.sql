USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[SerializeJSON_bak]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROCEDURE[dbo].[SerializeJSON_bak](
@ParameterSQL AS nVARCHAR(MAX),
@JSON AS NVARCHAR(MAX)  OUTPUT
)
AS
BEGIN
 DECLARE @SQL NVARCHAR(MAX)
DECLARE @XMLString nVARCHAR(MAX)
DECLARE @XML XML
DECLARE @Paramlist NVARCHAR(1000)
SET @Paramlist = N'@XML XML OUTPUT'
SET @SQL = 'WITH PrepareTable (XMLString)'
SET @SQL = @SQL + 'AS('
SET @SQL = @SQL + @ParameterSQL+ N'FOR XML RAW,TYPE,ELEMENTS'
SET @SQL = @SQL + N')'
SET @SQL = @SQL + N'SELECT @XML=[XMLString]FROM[PrepareTable]'
EXEC sp_executesql @SQL, @Paramlist, @XML=@XML OUTPUT
SET @XMLString=CAST(@XML   AS nvarchar(MAX))
 print @xmlString  

DECLARE @Row NVARCHAR(MAX)
DECLARE @RowStart INT
DECLARE @RowEnd INT
DECLARE @FieldStart INT
DECLARE @FieldEnd INT
DECLARE @KEY NVARCHAR(MAX)
DECLARE @Value NVARCHAR(MAX)
   
DECLARE @StartRoot NVARCHAR(100);SET @StartRoot=N'<row>'
DECLARE @EndRoot NVARCHAR(100);SET @EndRoot=N'</row>'
DECLARE @StartField NVARCHAR(100);SET @StartField=N'<'
DECLARE @EndField NVARCHAR(100);SET @EndField=N'>'
   
SET @RowStart=CharIndex(@StartRoot,@XMLString,0)

SET @JSON=''
WHILE @RowStart>0
BEGIN
    SET @RowStart=@RowStart+Len(@StartRoot)
	
    SET @RowEnd=CharIndex(@EndRoot,@XMLString,@RowStart)
	print '@rowEnd'
	print Len(@RowEnd)
    SET @Row=SubString(@XMLString,@RowStart,@RowEnd-@RowStart)
    SET @JSON=@JSON+'{'
   
    -- for each row
    SET @FieldStart=CharIndex(@StartField,@Row,0)
    WHILE @FieldStart>0
    BEGIN
        -- parse node key
        SET @FieldStart=@FieldStart+Len(@StartField)
        SET @FieldEnd=CharIndex(@EndField,@Row,@FieldStart)
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
