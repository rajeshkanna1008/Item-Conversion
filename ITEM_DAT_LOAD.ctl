options(SKIP=0)
LOAD DATA
infile *
TRUNCATE
INTO TABLE Item_staging_tbl
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS (segment1 ,
                   description ,
                   template_name ,
                   organization_code ,
                   process_flag                  "trim(:process_flag)" ,
                   error_message ,
                   creation_date                 SYSDATE,
                   created_by                   "fnd_global.user_id",
                   last_update_date              SYSDATE ,
                   last_updated_by               "fnd_global.user_id")