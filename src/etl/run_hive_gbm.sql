add jar /home/bigdata/gbm_test_file/udf/lib/GBMHiveUDF_V1.jar;
create temporary function gbm as 'com.vipshop.hadoop.platform.hive.dm_gbm_UDF';

drop table if exists temp_bigdata.dm_gxh_model_gbm;
create table temp_bigdata.dm_gxh_model_gbm as
select user_id,bs_warehouse,brand_id,
                gbm(
				bs_purchase_num,
				bs_median_price,
				us_buy_prob,
				bs_most_ct1_prop,
				bs_most_ct2_prop,
				uh_pb_l3m_gd_cnt,
				uh_ct1_ly_cart_cnt_ratio,
				uh_pb_lt_order_tf,
				uh_ct2_ly_cart_cnt_ratio,
				ct2_order_prop,
				ct2_mid_cycle,
                                uh_ct1_1w_rw_cnt,
				bs_flash_purchase,
				is_same_sex,
				uh_vmark_name,
				pb_level,
				uh_ct1_1w_is_order,
				bs_sale_style,
				active_type_combine,
				bs_warehouse
                    ) as score
from vipdm.dm_gxh_modeldata
where dt = get_dt_date(get_date(-1));

drop table if exists temp_bigdata.dm_gxh_model_gbm_output_sj;
create table temp_bigdata.dm_gxh_model_gbm_output_sj as
select user_id,bs_warehouse, collect_set(concat_ws(':',cast(brand_id as string), format_number(score,4)))
from temp_bigdata.dm_gxh_model_gbm
group by user_id,bs_warehouse;
