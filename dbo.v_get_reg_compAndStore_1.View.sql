USE [report_data]
GO
/****** Object:  View [dbo].[v_get_reg_compAndStore_1]    Script Date: 1/19/2022 9:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_get_reg_compAndStore_1]
AS
SELECT        vsc.MatrixMemberId, vsc.MemberInternalKey, vsc.BuyingUnitInternalKey, vsc.updatedDate, gs.city, cmsa.StoreInternalKey, CASE WHEN compID IS NULL THEN vsc.StartDate ELSE cmsa.UpdatedDate END AS Expr1, 
                         CASE WHEN compID IS NULL THEN vsc.R_compid ELSE gs.compID END AS compid, CASE WHEN gs.compID IS NULL THEN vsc.SegmentDescription ELSE gs.comp END AS comp, CASE WHEN gs.compID IS NULL 
                         THEN vsc.R_compid ELSE gs.storeid END AS storeid, CASE WHEN gs.compID IS NULL THEN vsc.SegmentDescription ELSE gs.storename END AS StoreName, gs.StoreType
FROM            dbo.v_segment_comp AS vsc LEFT OUTER JOIN
                         dbo.CRM_MemberStoreAssign_shell AS cmsa ON vsc.MemberInternalKey = cmsa.MemberInternalKey AND vsc.MatrixMemberId = cmsa.MatrixMemberId LEFT OUTER JOIN
                         dbo.store_gs AS gs ON cmsa.StoreInternalKey = gs.StoreInternalKey AND cmsa.MatrixMemberId = gs.MatrixMemberId
WHERE        (vsc.MatrixMemberId IN (1, 6, 7, 8, 9))
UNION ALL
SELECT        vsc.MatrixMemberId, vsc.MemberInternalKey, vsc.BuyingUnitInternalKey, vsc.updatedDate, '' AS city, '' AS StoreInternalKey, NULL, vsc.R_compid AS compid, vsc.SegmentDescription AS comp, store.StoreCode AS storeid, 
                         store.StoreName StoreName, '' AS StoreType
FROM            dbo.v_segment_comp AS vsc LEFT JOIN
                         SxVirtualStore store ON vsc.R_compid = store.CompId
WHERE        vsc.MatrixMemberId IN (4, 5)
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[23] 4[4] 2[60] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = -1248
         Left = 0
      End
      Begin Tables = 
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 10
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_get_reg_compAndStore_1'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_get_reg_compAndStore_1'
GO
