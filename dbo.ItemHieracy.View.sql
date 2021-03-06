USE [report_data]
GO
/****** Object:  View [dbo].[ItemHieracy]    Script Date: 1/19/2022 9:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE VIEW [dbo].[ItemHieracy]
AS
WITH ih1(id, hierarchKey, Description, HierarchyLevel, Parentid, CategoryKey, matrixMemberid)
AS (SELECT        Id, CategoryKey AS hierarchKey, Description, HierarchyLevel, ParentId, CategoryKey, MatrixMemberId
FROM            HOST_Shell_UAT.dbo.ItemHierarchyTemplateLine AS h
WHERE        (ViewId = 0)
UNION ALL
      SELECT        ih.Id, ih.CategoryKey AS hierarchKey, ih.Description, ih.HierarchyLevel, ih.ParentId, tmp.CategoryKey, 
ih.MatrixMemberId
FROM            HOST_Shell_UAT.dbo.ItemHierarchyTemplateLine AS ih INNER JOIN
ih1 AS tmp ON tmp.Parentid = ih.CategoryKey AND tmp.matrixMemberid = ih.MatrixMemberId
WHERE        (ih.ViewId = 0))
    SELECT        id, Description, hierarchKey, HierarchyLevel, Parentid, CategoryKey, matrixMemberid
     FROM            ih1 AS hie
GO
