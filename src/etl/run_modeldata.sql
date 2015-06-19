drop table if exists temp_bigdata.dm_gxh_modeldata;
create table temp_bigdata.dm_gxh_modeldata as
select  
    a.user_id,
    a.brand_id,
    a.bs_warehouse,
    coalesce(bs_most_ct1_prop, -1) as bs_most_ct1_prop,-- 有问题，用中位数填补
    coalesce(bs_most_ct2_prop, -1) as bs_most_ct2_prop,-- 有问题，用中位数填补
    coalesce(vmark_name, '') as uh_vmark_name,
    coalesce(is_same_sex, '') as is_same_sex,
    coalesce(bs_sale_style, '') as bs_sale_style,
    coalesce(pb_level, '') as pb_level,
    coalesce(bs_flash_purchase, '') as bs_flash_purchase,
    coalesce(active_type_combine, '') as active_type_combine,
    coalesce(is_parent, '') as uh_is_parent,
    coalesce(bs_median_price, -1) as bs_median_price,   -- 有问题，用中位数填补
    coalesce(bs_purchase_num, -1) as bs_purchase_num,   -- 有问题，用中位数填补
    coalesce(ct2_order_prop, -1) as ct2_order_prop,
    coalesce(ct2_mid_cycle, -1) as ct2_mid_cycle,
    coalesce(uh_pb_lt_order_tf, -1) as uh_pb_lt_order_tf,
    coalesce(uh_pb_l3m_sales_cnt, -1) as uh_pb_l3m_gd_cnt,
    coalesce(us_buy_prob, -1) as us_buy_prob,
    coalesce(uh_ct1_ly_cart_cnt_ratio, -1) as uh_ct1_ly_cart_cnt_ratio,
    coalesce(uh_ct2_ly_cart_cnt_ratio, -1) as uh_ct2_ly_cart_cnt_ratio,
    coalesce(uh_ct1_1w_rw_cnt, -1) as uh_ct1_1w_rw_cnt,
    coalesce(uh_ct1_1w_is_order, -1) as uh_ct1_1w_is_order 
from temp_bigdata.dm_gxh_model_tmp a 
left outer join (select * from vipdm.dm_gxh_log_user_rf_brd_online where dt = get_dt_date(get_date(-1)) ) pb on a.user_id = pb.user_id and a.pt_brand_id = pb.pt_brand_id
left outer join (select * from vipdm.dm_gxh_log_user_rf_cat_online where dt = get_dt_date(get_date(-1)) ) cat on a.user_id = cat.user_id and a.ct_second = cat.ct_second
left outer join (select * from vipdm.dm_gxh_log_user_watch where dt = get_dt_date(get_date(-1)) ) watch on a.user_id = watch.user_id and a.ct_first = watch.ct_first
;

