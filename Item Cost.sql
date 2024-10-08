SELECT
    msi.segment1                       "ITEM_NUM",
    msi.description                    "ITEM_DESCRIPTION",
    msi.primary_unit_of_measure        "UOM",
    cct.cost_type                      "COST TYPE",
    cic.defaulted_flag                 "USE DEFAULT CONTROLS",
    msi.inventory_asset_flag           "INVENTORY ASSET",
    cic.based_on_rollup_flag           "BASED ON ROLLUP",
    cic.lot_size,
    cic.shrinkage_rate                 "MANUFACTURING SHRINKAGE",
    cic.item_cost                      "UNIT COST",
    cic.material_cost                  "MATERIAL",
    cic.material_overhead_cost         "MATERIAL_OVERHEAD",
    cic.resource_cost                  "RESOURCE",
    cic.outside_processing_cost        "OUTSIDE_PROCESSING",
    cic.overhead_cost                  "OVERHEAD",
    gcc.concatenated_segments          "COGS_ACCOUNT",
    gcc1.concatenated_segments         "SALES_ACCOUNT",
    flv.meaning                        "MAKE/BUY",
    msi.default_include_in_rollup_flag "INCLUDE IN ROLLUP",
    (
        SELECT
            mic.segment1
            || '.'
            || mic.segment2
            || '.'
            || mic.segment3
            || '.'
            || mic.segment4
            || '.'
            || mic.segment5
            || '.'
            || mic.segment6
        FROM
            mtl_item_categories_v mic,
            mtl_category_sets     mcs
        WHERE
                mic.category_set_id = mcs.category_set_id
            AND mcs.category_set_name = 'ENVS CST Category Set'
            AND mic.inventory_item_id = msi.inventory_item_id
            AND mic.organization_id = msi.organization_id
    )                                  "COST CATEGORY"
FROM
    mtl_system_items_b           msi,
    cst_cost_types               cct,
    cst_item_costs               cic,
    org_organization_definitions ood,
    gl_code_combinations_kfv     gcc,
    gl_code_combinations_kfv     gcc1,
    fnd_lookup_values            flv
WHERE
        1 = 1
--    and cic.item_cost is not null
--    and cic.item_cost <> 0
    AND cct.cost_type_id = cic.cost_type_id
    AND cic.inventory_item_id = msi.inventory_item_id
    AND cic.organization_id = msi.organization_id
    AND msi.organization_id = ood.organization_id
    AND gcc.chart_of_accounts_id = ood.chart_of_accounts_id
    AND gcc.code_combination_id = msi.cost_of_sales_account
    AND gcc1.chart_of_accounts_id = ood.chart_of_accounts_id
    AND gcc1.code_combination_id = msi.expense_account
    AND flv.lookup_type = 'MTL_PLANNING_MAKE_BUY'
    AND flv.lookup_code = msi.planning_make_buy_code
    AND flv.language = 'US'
    AND ood.organization_code = 'V1'
and msi.segment1='Test_GSTS'
and msi.inventory_item_id = 253209