USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[stp_GetJSONSegmentMember]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/**********************************************************************************************************************
 Name:		stp_GetJSONSegmentMember

 Description:  	Search for Club Card by specific segment(s) for Digital channels to push message

                                                                                			
 Returns:      JSON string with ClubCardId . 
 Example:		
	declare
		 @RetailerId smallint='1'
		,@Segments nvarchar(max) ='''20190122'',''4444'''
		,@SerialNo varchar(20)='2019122574561' 
		
	exec stp_GetJSONSegmentMember
		 @RetailerId 
		,@Segments 
		,@SerialNo 
		
	select @JSONStr
		
-------------------------------------------------------------------------------------------------------------------------                                                                               			
WHO				WHEN		WHAT
-------------------------------------------------------------------------------------------------------------------------
PeterF		2016/10/26		create

***********************************************************************************************************************/

CREATE   PROCEDURE [dbo].[stp_GetJSONSegmentMember] @RetailerId      SMALLINT,
                                                 @Segments        NVARCHAR(max),
                                                 @SerialNo        varchar(20)
AS
  BEGIN
      DECLARE @MatrixMemberId      INT,
              @SQLGetSegmentMember NVARCHAR(max)
			 ,@FilePath NVARCHAR(300)=  'M:\upload\'  
		     ,@Expoprtfilename nvarchar(200)
		     ,@Server VARCHAR(max)   ='Loyalty_Shell_1.dbo.'
			-- print @segments;
		--	 insert  a(aaa) values( @segments)
	select @FilePath=erc.ExtractLocalPath  from REPORT_DATA..extractReportConfig erc where erc.MatrixMemberId=@MatrixMemberId
 
      --,@IssueDate nvarchar(max) ='2016-10-01'
--set @MatrixMemberId=@RetailerId

	select @MatrixMemberId=MatrixMemberId from RetailCode_MP where RetailerId=@RetailerId  -- fixed RetailerID <> MatrixMemberID issue, updated by Rich on 2018-5-12
    	select @FilePath=erc.ExtractLocalPath  from REPORT_DATA..extractReportConfig erc where erc.ReportName='CMS_SegmentMember'
 
	delete  CMS_SegmentMember;
	  SET @SQLGetSegmentMember=' INSERT INTO  report_data..CMS_SegmentMember select    ClubCardId  as  member_card_no from ( 
	select distinct b.ClubCardId 
	from 
	'+@Server+'CRM_MemberSegment a(nolock)
	,'+@Server+'CRM_Clubcard b (nolock)
	,'+@Server+'CRM_Segment c (nolock)
	where 1=1
	and  B.RestrictionId=1
	and (a.MatrixMemberId='
                               + CONVERT(NVARCHAR(max), @MatrixMemberId)
                               + ' and a.MatrixMemberId=b.MatrixMemberId and a.MatrixMemberId=c.MatrixMemberId)
	and (c.SegmentId in (' + @Segments
                               + ') and a.SegmentInternalKey=c.SegmentInternalKey)
	and a.MemberInternalKey=b.MemberInternalKey 
	  union all   
		   select distinct b.ClubCardId 
	from 
	'+@Server+'CRM_BuyingUnitSegment a(nolock)
	,'+@Server+'CRM_Clubcard b (nolock)
	,'+@Server+'CRM_Segment c (nolock)
	,'+@Server+'CRM_Member cm (nolock)
	where 1=1
	and  B.RestrictionId=1
	and (a.MatrixMemberId='
                               + CONVERT(NVARCHAR(max), @MatrixMemberId)
                               + ' and a.MatrixMemberId=b.MatrixMemberId and a.MatrixMemberId=c.MatrixMemberId)
	and (c.SegmentId in (' + @Segments+
                               + ') and a.SegmentInternalKey=c.SegmentInternalKey)
	 and cm.BuyingUnitInternalKey=a.BuyingUnitInternalKey and cm.ExternalMemberKey=b.ClubCardId
	   ) b ORDER BY 1 ';

	--declare @x table (ClubCardId nvarchar(max))
	--insert into @x
	exec (@SQLGetSegmentMember)
   select  @SQLGetSegmentMember

	declare @looptime int,@memberTotalCount int ,@i int;
	declare @member_card_no varchar(64);
	select @memberTotalCount=count(1) from CMS_SegmentMember;
	declare @loop float
	       ,@EachEtractMemberCount INT=200000
		   ,@SQL_TEXT NVARCHAR(MAX)
		   ,@TABLE  VARCHAR(50);
	set @loop=0.000
	set @loop=@memberTotalCount*1.000/ @EachEtractMemberCount
  
	set @looptime=ceiling(@loop);
	
	set @i=1 
	while @i<=@looptime 
begin 
	set @sql_text=' if   exists   (select   *   from   dbo.sysobjects   where   id   =   object_id(N'''
	+'CMS_SegmentMember'+ltrim(str(@RetailerId))+'_'+ltrim(str(@i))+ ''')   and   OBJECTPROPERTY(id,   N'''+'IsUserTable'+''')   =   1)  

	   
  drop   table '+ 'CMS_SegmentMember'+ltrim(str(@RetailerId))+'_'+ltrim(str(@i));
  print @sql_text;
   exec( @sql_text);
     if @i=1 
	 set @sql_text=' select top '+ str(@EachEtractMemberCount) +'*  into   CMS_SegmentMember'+ltrim(str(@RetailerId))+'_'+ltrim(str(@i))
	  +' from CMS_SegmentMember  order by member_card_no';
	 else
 set @sql_text=' select top '+ str(@EachEtractMemberCount) +' * into   CMS_SegmentMember'+ltrim(str(@RetailerId))+'_'+ltrim(str(@i))
	  +' from CMS_SegmentMember where member_card_no> (select top 1 member_card_no from  CMS_SegmentMember'+ltrim(str(@RetailerId))+'_'+ltrim(str(@i-1))
	   +' order by member_card_no  desc)   order by member_card_no';

	 exec( @sql_text);

	 
	  print @sql_text;

	--set  @sql_text= 'select top 1 @member_card_no=member_card_no  from  R10_member_list_'+ltrim(str(@i)) +' order by  member_card_no  desc'
	--exec( @sql_text);

	
	
	  set  @table='CMS_SegmentMember'+ltrim(str(@RetailerId))+'_'+ltrim(str(@i));
	    print 'table:'
	  print @table ;
      set  @Expoprtfilename=@filepath+'\CMS_SegmentMember'+ltrim(str(@RetailerId))+@SerialNo+'_'+ltrim(str(@i))+'.csv';
	  print @Expoprtfilename
      exec  report_data.[dbo].est_export_cvs @table,@Server,@Expoprtfilename;
	  set @i=@i+1;	
  end 
     set  @Expoprtfilename=@filepath+'\CMS_SegmentMember'+ltrim(str(@RetailerId))+@SerialNo+'.ok';
	  print @Expoprtfilename
      exec  report_data.[dbo].est_export_cvs @table,@Server,@Expoprtfilename,' where 1=2';
		--select @JSONStr
End
GO
