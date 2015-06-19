package com.vipshop.hadoop.platform.hive;

import org.apache.hadoop.hive.ql.exec.UDF;
import org.apache.hadoop.hive.ql.exec.Description;


  /**
   * Model_target_UDF
   *
   **/
public class dm_gbm_UDF extends UDF {

private static dm_gbm gbm = new dm_gbm();

public double evaluate(
	// doubles
	Double bs_purchase_num,
	Double bs_median_price,
	Double us_buy_prob,
	Double bs_most_ct1_prop,
	Double bs_most_ct2_prop,
	Double uh_pb_l3m_gd_cnt,
	Double uh_ct1_ly_cart_cnt_ratio,
	Double uh_pb_lt_order_tf,
	Double uh_ct2_ly_cart_cnt_ratio,
	Double ct2_order_prop,
	Double ct2_mid_cycle,
	Double uh_ct1_1w_rw_cnt,
// Strings
	String bs_flash_purchase,
	String is_same_sex,
	String uh_vmark_name,
	String pb_level,
	String uh_ct1_1w_is_order,
	String bs_sale_style,
	String active_type_combine,
	String pb_is_like,
	String bs_warehouse,
	String bs_most_ct2
) {

	gbm.bs_purchase_num = bs_purchase_num.doubleValue();
	gbm.bs_median_price = bs_median_price.doubleValue();
	gbm.us_buy_prob = us_buy_prob.doubleValue();
	gbm.bs_most_ct1_prop = bs_most_ct1_prop.doubleValue();
	gbm.bs_most_ct2_prop = bs_most_ct2_prop.doubleValue();
	gbm.uh_pb_l3m_gd_cnt = uh_pb_l3m_gd_cnt.doubleValue();
	gbm.uh_ct1_ly_cart_cnt_ratio = uh_ct1_ly_cart_cnt_ratio.doubleValue();
	gbm.uh_pb_lt_order_tf = uh_pb_lt_order_tf.doubleValue();
	gbm.uh_ct2_ly_cart_cnt_ratio = uh_ct2_ly_cart_cnt_ratio.doubleValue();
	gbm.ct2_order_prop = ct2_order_prop.doubleValue();
	gbm.ct2_mid_cycle = ct2_mid_cycle.doubleValue();
	gbm.uh_ct1_1w_rw_cnt = uh_ct1_1w_rw_cnt.doubleValue();
	gbm.bs_flash_purchase = ( null == bs_flash_purchase ? " " : bs_flash_purchase );
	gbm.is_same_sex = ( null == is_same_sex ? " " : is_same_sex );
	gbm.uh_vmark_name = ( null == uh_vmark_name ? " " : uh_vmark_name );
	gbm.pb_level = ( null == pb_level ? " " : pb_level );
	gbm.uh_ct1_1w_is_order = ( null == uh_ct1_1w_is_order ? " " : uh_ct1_1w_is_order );
	gbm.bs_sale_style = ( null == bs_sale_style ? " " : bs_sale_style );
	gbm.active_type_combine = ( null == active_type_combine ? " " : active_type_combine );
	gbm.pb_is_like = ( null == pb_is_like ? " " : pb_is_like );
	gbm.bs_warehouse = ( null == bs_warehouse ? " " : bs_warehouse );
	gbm.bs_most_ct2 = ( null == bs_most_ct2 ? " " : bs_most_ct2 );

	return gbm.treenet();
	}
}
