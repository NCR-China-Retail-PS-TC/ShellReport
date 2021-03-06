USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[checkBalance]    Script Date: 1/19/2022 9:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create  procedure [dbo].[checkBalance]  as 
begin 
exec est_sc '2020-05-11'
exec erp_ds_sc '2020-05-10'

select sum(r1.reward_point)  from R1_2_tran_reward r1
select sum(r1.reward_point)  from DS_R1_2_tran_reward r1

select sum(a ) from (
select sum(e.point_number)  a,e.business_date from E1_single_leg_reward e where e.Create_date='2020-05-10' and e.RetailerId=3 group by e.business_date
union all
select sum(e.point_number)  a,e.business_date from e4_mult_reward e where e.Create_date='2020-05-10' and e.RetailerId=3 group by e.business_date
)b

select sum(a ) from (
select sum(e.point_number)  a,Create_date ,e.point_type  from E1_single_leg_reward e
   where e.business_date='2020-05-18' and e.RetailerId=3 group by Create_date,e.point_type
union all
select sum(e.point_number)  a,Create_date ,e.point_type from e4_mult_reward e where e.business_date='2020-05-18' and e.RetailerId=3 group by Create_date,e.point_type
)b

select  *  from E1_single_leg_reward e where e.business_date='2020-05-02'  and e.Create_date='2020-05-03' and e.RetailerId=3  order by store_name


exec main_interface_etl_sc  '2020-05-09'
exec main_interface_etl_sc  '2020-05-10'
exec main_interface_etl_sc  '2020-05-11'
end;
GO
