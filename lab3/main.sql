create or replace procedure cmp_func(prod in varchar2, dev in varchar2)
authid current_user
as
    v_count number;
    prod_name varchar2(100) :=upper(prod);
    dev_name varchar2(100) :=upper(dev);
    v_script varchar2(4000);
    v_prod_arg_count number;
begin

    for funcs in (select distinct name from all_source where owner = UPPER(dev_name) and type = 'FUNCTION'
                        minus select distinct name from all_source where owner = UPPER(prod_name) and type = 'FUNCTION')
    loop
        dbms_output.put_line('No dev #' || funcs.name || '# function in prod schema');
    end loop;
    dbms_output.put_line('123');
    for dev_func in (select object_name, dbms_metadata.get_ddl('FUNCTION', object_name, dev_name) as func_text from all_objects where object_type = 'FUNCTION' and owner = dev_name)
    loop
        dbms_output.put_line('123');
    
        v_count := 0;
        select count(*) into v_count
        from all_objects
        where object_type = 'FUNCTION' and object_name = dev_func.object_name and owner = prod_name;
        if v_count = 0 then
            v_script := dev_func.func_text;
            v_script := replace(v_script, dev_name, prod_name);
            dbms_output.put_line(v_script);
        end if;
    end loop;
    
    for prod_func in (select object_name from all_objects where object_type = 'FUNCTION' and owner = prod_name) loop
        v_count := 0;
        select count(*) into v_count
        from all_objects
        where object_type = 'FUNCTION' and object_name = prod_func.object_name and owner = dev_name;
        if v_count = 0 then
            dbms_output.put_line('drop function ' || prod_func.object_name);
            -- execute IMMEDIATE 'drop function ' || prod || '.' || prod_func.object_name;
        end if;
    end loop;
    
    for dev_func in (select object_name, dbms_metadata.get_ddl('FUNCTION', object_name, dev_name) as proc_text from all_objects where object_type = 'FUNCTION' and owner = dev_name)
    loop
        v_count := 0;
        select count(*) into v_count from all_objects where object_type = 'FUNCTION' and object_name = dev_func.object_name and owner = prod_name;
        if v_count > 0 then
            for tmp in (SELECT argument_name, position, data_type, in_out
                FROM all_arguments
                WHERE owner = dev_name
                AND object_name = dev_func.object_name) loop
        
                select count(*) into v_prod_arg_count from all_arguments
                                                            WHERE owner = prod_name
                                                            AND object_name = dev_func.object_name
                                                            and argument_name = tmp.argument_name
                                                            and position = tmp.position
                                                            and data_type = tmp.data_type
                                                            and in_out = tmp.in_out;
                if v_prod_arg_count = 0 then
                    dbms_output.put_line('incorrect dev proc #' || dev_func.object_name || '# declaration in ' || prod_name || 'schema');
                    dbms_output.put_line('drop procedure ' || prod_name || '.' || dev_func.object_name);
                    v_script := dev_func.proc_text;
                    v_script := replace(v_script, dev_name, prod_name);
                    dbms_output.put_line(v_script);
                end if;
              end loop;
        end if;
    end loop;
end;

/

create or replace procedure cmp_indx(prod in varchar2, dev in varchar2)
authid current_user
as
    v_count number;
    prod_name varchar2(100) :=upper(prod);
    dev_name varchar2(100) :=upper(dev);
    v_script varchar2(4000);
begin

    for indxs in (select distinct INDEX_NAME from ALL_INDEXES  where TABLE_OWNER = UPPER(dev_name) and INDEX_NAME not like 'SYS%'
                        minus select distinct INDEX_NAME from ALL_INDEXES where TABLE_OWNER = UPPER(prod_name) and INDEX_NAME not like 'SYS%')
    loop
        dbms_output.put_line('No dev #' || indxs.INDEX_NAME || '# index in prod schema');
    end loop;
    
    for dev_indx in (select object_name, dbms_metadata.get_ddl('INDEX', object_name, dev_name) as index_text from all_objects where object_type = 'INDEX' and OWNER = dev_name  and object_name not like 'SYS%')
    loop
        dbms_output.put_line('123');
    
        v_count := 0;
        select count(*) into v_count
        from all_objects
        where object_type = 'INDEX' and object_name = dev_indx.object_name and OWNER = prod_name;
        if v_count = 0 then
            v_script := dev_indx.index_text;
            v_script := replace(v_script, dev_name, prod_name);
            dbms_output.put_line(v_script);
        end if;
    end loop;
    
    for prod_indx in (select object_name from all_objects where object_type = 'INDEX' and owner = prod_name and object_name not like 'SYS%' and object_name not like '%_PK') loop
        v_count := 0;
        select count(*) into v_count
        from all_objects
        where object_type = 'INDEX' and object_name = prod_indx.object_name and owner = dev_name and object_name not like 'SYS%' and object_name not like '%_PK';
        if v_count = 0 then
            dbms_output.put_line('drop index ' || prod_indx.object_name);
            execute IMMEDIATE 'drop index ' || prod || '.' || prod_indx.object_name;
        end if;
    end loop;
end;

/
create or replace procedure cmp_prc (prod in varchar2, dev in varchar2)
authid current_user
as
    v_count number;
    prod_name varchar2(100) :=upper(prod);
    dev_name varchar2(100) :=upper(dev);
    v_script varchar2(4000);
    v_prod_arg_count number;
begin
  for proc in (select object_name
               from all_procedures -- store all funcs and proc
               where owner = dev_name and OBJECT_TYPE='PROCEDURE'
               minus
               select object_name
               from all_procedures
               where owner = prod_name and OBJECT_TYPE='PROCEDURE')
  loop
    dbms_output.put_line('No dev #' || proc.object_name || '# procedure in prod schema');
  end loop;

    
    for dev_proc in (select object_name, dbms_metadata.get_ddl('PROCEDURE', object_name, dev_name) as proc_text from all_objects where object_type = 'PROCEDURE' and owner = dev_name)
    loop
        v_count := 0;
        select count(*) into v_count from all_objects where object_type = 'PROCEDURE' and object_name = dev_proc.object_name and owner = prod_name;
        if v_count = 0 then
            v_script := dev_proc.proc_text;
            v_script := replace(v_script, dev_name, prod_name);
            dbms_output.put_line(v_script);
        end if;
    end loop;

    for prod_proc in (select object_name from all_objects where object_type = 'PROCEDURE' and owner = prod_name) loop
        v_count := 0;
        select count(*) into v_count from all_objects where object_type = 'PROCEDURE' and object_name = prod_proc.object_name and owner = dev_name;
        if v_count = 0 then
            dbms_output.put_line('drop procedure ' || prod_name || '.' || prod_proc.object_name);
        end if;
    end loop;
    
    for dev_proc in (select object_name, dbms_metadata.get_ddl('PROCEDURE', object_name, dev_name) as proc_text from all_objects where object_type = 'PROCEDURE' and owner = dev_name)
    loop
        v_count := 0;
        select count(*) into v_count from all_objects where object_type = 'PROCEDURE' and object_name = dev_proc.object_name and owner = prod_name;
        if v_count > 0 then
            for tmp in (SELECT argument_name, position, data_type, in_out
                FROM all_arguments
                WHERE owner = dev_name
                AND object_name = dev_proc.object_name) loop
        
                select count(*) into v_prod_arg_count from all_arguments
                                                            WHERE owner = prod_name
                                                            AND object_name = dev_proc.object_name
                                                            and argument_name = tmp.argument_name
                                                            and position = tmp.position
                                                            and data_type = tmp.data_type
                                                            and in_out = tmp.in_out;
                if v_prod_arg_count = 0 then
                    dbms_output.put_line('incorrect dev proc #' || dev_proc.object_name || '# declaration in ' || prod_name || 'schema');
                    dbms_output.put_line('drop procedure ' || prod_name || '.' || dev_proc.object_name);
                    v_script := dev_proc.proc_text;
                    v_script := replace(v_script, dev_name, prod_name);
                    dbms_output.put_line(v_script);
                end if;
              end loop;
        end if;
    end loop;
end;

/

create or replace procedure cmp_tbl (prod in varchar2, dev in varchar2
) authid current_user is
    v_dev_table_name all_tables.table_name%type;
    v_table_count integer;
    v_dev_col_count integer;
    v_prod_col_count integer;
    v_script varchar2(4000);
    v_count_circular number;
    v_missing_cols_in_prod_count number;
    prod_name varchar2(100) := upper(prod);
    dev_name varchar2(100) := upper(dev);
    v_sql varchar2(4000);
    v_fk_cons_name varchar2(30);
    v_table_name varchar2(30);
    v_column_name varchar2(30);
    ddl_script varchar2(10000);
    TYPE string_list_t IS
        TABLE OF VARCHAR2(100);
    dev_constraints_set  string_list_t;
        prod_constraints_set string_list_t;

    type table_list_type is table of varchar2(100);
    v_table_list table_list_type := table_list_type();
    v_processed_tables table_list_type := table_list_type();
    cur_dev_table_name varchar2(100);
    
    cursor cur_fk_cons is
        select distinct cons.constraint_name, cols.table_name, cols.column_name
        from all_constraints cons
        join all_cons_columns cols on cons.owner = cols.owner and cons.table_name = cols.table_name and cons.constraint_name = cols.constraint_name
        where cons.constraint_type = 'R' and cols.owner = dev_name;
        
    cursor cur_pk_cons is
        select distinct cons.constraint_name, cols.table_name, cols.column_name
        from all_constraints cons
        join all_cons_columns cols on cons.owner = cols.owner and cons.table_name = cols.table_name and cons.constraint_name = cols.constraint_name
        where cons.constraint_type = 'P' and cols.owner = dev_name;

    procedure process_table(
    p_table_name in varchar2
  ) is
    cursor fk_cur is
      select cc.table_name as child_table
      from all_constraints pc
      join all_constraints cc on pc.constraint_name = cc.r_constraint_name
      where pc.constraint_type = 'P'
      and cc.constraint_type = 'R'
      and pc.owner = dev_name
      and cc.owner = dev_name
      and pc.table_name = p_table_name;

    v_child_table varchar2(100);
  begin
    if p_table_name not member of v_processed_tables then
      v_processed_tables.extend;
      v_processed_tables(v_processed_tables.last) := p_table_name;

      for fk_rec in fk_cur loop
        v_child_table := fk_rec.child_table;
        process_table(v_child_table);
      end loop;

      v_table_list.extend;
      v_table_list(v_table_list.last) := p_table_name;
    end if;
  end process_table;

begin

    -- find circular
    select count(*) into v_count_circular from (with table_hierarchy as (select child_owner, child_table, parent_owner, parent_table
                                         from (select owner child_owner, table_name child_table, r_owner parent_owner, r_constraint_name constraint_name
                                               from all_constraints where constraint_type = 'R' and owner = 'DEV')
                                                  join (select owner parent_owner, constraint_name, table_name parent_table
                                                        from all_constraints where constraint_type = 'P' and owner = 'DEV')
                                                       using (parent_owner, constraint_name))
                select distinct child_owner, child_table
                from (select *
                      from table_hierarchy where (child_owner, child_table) in (select parent_owner, parent_table
                                                           from table_hierarchy)) a
                where connect_by_iscycle = 1
                connect by nocycle (prior child_owner, prior child_table) = ((parent_owner, parent_table))
                );

    -- find dev table that doesn't exist in prod
    if v_count_circular > 0 then
        dbms_output.put_line('circular foreign key reference detected in DEV schema.');
        -- return;
    end if;

    for table_rec in (select table_name from all_tables where owner = dev_name order by table_name) loop
        process_table(table_rec.table_name);
    end loop;
    
    
    
    
    
    -- print missing cols
    for i in reverse 1..v_table_list.count loop
    -- for dev_tab_rec in (select table_name from all_tables where owner = dev_name) loop
        v_dev_table_name := v_table_list(i);

        select count(*) into v_table_count
        from all_tables
        where owner = prod_name
        and table_name = v_dev_table_name;

        if v_table_count = 0 then
            dbms_output.put_line('No dev table #' || v_dev_table_name || '# is in prod schema.');
        else
            -- compare table structure
            select count(*) into v_dev_col_count from all_tab_cols where owner = dev_name and table_name = v_dev_table_name;

            select count(*) into v_prod_col_count from all_tab_cols where owner = prod_name and table_name = v_dev_table_name;

            -- dbms_output.put_line('table ' || v_dev_table_name || ' dev: ' || to_char(v_dev_col_count));
            -- dbms_output.put_line('table ' || v_dev_table_name || ' prod: ' || to_char(v_prod_col_count));

            if v_dev_col_count > v_prod_col_count then
                dbms_output.put_line('Table ' || v_dev_table_name || ' has ' || (v_dev_col_count - v_prod_col_count) || ' more columns in development schema.');
            end if;

            for dev_col_rec in (select column_name from all_tab_cols where owner = dev_name and table_name = v_dev_table_name and column_name not like 'SYS%') loop
                select count(*) into v_table_count from all_tab_cols where owner = prod_name and table_name = v_dev_table_name and column_name = dev_col_rec.column_name;

                if v_table_count = 0 then
                    dbms_output.put_line('No dev column #' || dev_col_rec.column_name || '# in dev table ' || v_dev_table_name || ' in production schema.');
                end if;
            end loop;
        end if;
    end loop;










    for i in reverse 1..v_table_list.count loop
    --for dev_tab_rec in (select table_name from all_tables where owner = dev_name) loop
            -- v_dev_table_name := dev_tab_rec.table_name;
            v_dev_table_name := v_table_list(i);

            select count(*) into v_table_count from all_tables where owner = prod_name and table_name = v_dev_table_name;

            if v_table_count = 0 then
                -- no dev table in prod, gen script
                select dbms_metadata.get_ddl('TABLE', v_dev_table_name, dev_name) into v_script from dual;
                v_script := replace(v_script, dev_name, prod_name);
                dbms_output.put_line(v_script);
            else
                -- cmpr table struct
                select count(*) into v_dev_col_count from all_tab_cols where owner = dev_name and table_name = v_dev_table_name;

                select count(*) into v_prod_col_count from all_tab_cols where owner = prod_name and table_name = v_dev_table_name;

                -- if v_dev_col_count > v_prod_col_count then
                    -- script to add missing cols
                    v_missing_cols_in_prod_count := 0;
                    v_script := 'alter table ' || prod_name || '.' || v_dev_table_name || ' add (';
                    for dev_col_rec in (select column_name, data_type, data_length, data_precision, data_scale
                                        from all_tab_cols where owner = dev_name and table_name = v_dev_table_name) loop
                        select count(*) into v_table_count from all_tab_cols where owner = prod_name and table_name = v_dev_table_name and column_name = dev_col_rec.column_name;

                        if v_table_count = 0 and dev_col_rec.column_name not like 'SYS%' then
                            v_missing_cols_in_prod_count := v_missing_cols_in_prod_count + 1;
                            v_script := v_script || dev_col_rec.column_name || ' ' || dev_col_rec.data_type;
                            if dev_col_rec.data_type in ('VARCHAR2', 'NVARCHAR2', 'RAW') then
                                v_script := v_script || '(' || dev_col_rec.data_length || ')';
                            elsif dev_col_rec.data_type in ('NUMBER') then
                                if (dev_col_rec.data_precision is not null) then
                                    v_script := v_script || '(' || dev_col_rec.data_precision || ')';
                                end if;
                                if (dev_col_rec.data_scale is not null) then
                                    v_script := v_script || ', ' || dev_col_rec.data_scale || ')';
                                end if;
                            end if;
                            v_script := v_script || ', ';
                        end if;
                    end loop;
                    v_script := rtrim(v_script, ', ') || ')';
                    if (v_missing_cols_in_prod_count > 0) then
                        dbms_output.put_line(v_script);
                    end if;
                -- else
                    -- script to rem extra cols
                    for prod_col_rec in (select column_name, data_type, data_length, data_precision, data_scale
                                        from all_tab_cols where owner = prod_name and table_name = v_dev_table_name and column_name not like 'SYS%') loop
                        select count(*) into v_table_count from all_tab_cols where owner = dev_name and table_name = v_dev_table_name and column_name = prod_col_rec.column_name;

                        if v_table_count = 0 then
                            v_script := 'alter table ' || prod_name || '.' || v_dev_table_name || ' drop column ' || upper(prod_col_rec.column_name);
                            dbms_output.put_line(v_script);
                        end if;
                    end loop;
                -- end if;
            end if;
        end loop;







        -- check extra prod tbls ///////////////
        for prod_tab_rec in (select table_name from all_tables where owner = prod_name) loop
            select count(*) into v_table_count from all_tables where owner = dev_name and table_name = prod_tab_rec.table_name;

            if v_table_count = 0 then
                -- gen script
                dbms_output.put_line('drop table ' || prod_name || '.' || prod_tab_rec.table_name);
            end if;
        end loop;
        
        
        
        
        
        -- drop constraint from prod
        for i in reverse 1..v_table_list.count loop
        v_dev_table_name := v_table_list(i);
        for rec_fk_cons in (
            select distinct cons.constraint_name, cols.table_name, cols.column_name
            from all_constraints cons
            join all_cons_columns cols on cons.owner = cols.owner and cons.table_name = cols.table_name and cons.constraint_name = cols.constraint_name
            where cols.owner = prod_name and cols.table_name = v_dev_table_name
        ) loop
        begin
            select rec_fk_cons.constraint_name, rec_fk_cons.table_name, rec_fk_cons.column_name
            into v_fk_cons_name, v_table_name, v_column_name
            from dual
            where not exists (
                select 1
                from all_constraints cons
                join all_cons_columns cols on cons.owner = cols.owner and cons.table_name = cols.table_name and cons.constraint_name = cols.constraint_name and cols.column_name = v_column_name
                where cols.owner = dev_name and cols.table_name = v_table_name and cons.constraint_name = v_fk_cons_name
            );
    
            if v_fk_cons_name is not null and v_fk_cons_name not like 'SYS%' then
                -- drop foreign key constraint from prod_schema
                v_sql := 'alter table ' || prod_name || '.' || v_table_name ||
                         ' drop constraint ' || v_fk_cons_name;
                dbms_output.put_line(v_sql);
            end if;
        exception
           when others then
           if rec_fk_cons.constraint_name not like 'SYS%' then
            dbms_output.put_line('Error removing foreign key ' || rec_fk_cons.constraint_name || ' from table ' || rec_fk_cons.table_name || ': ' || sqlerrm);
            end if;
        end;
        end loop;
        
    end loop;
    
    -- add missing constr
    for i in reverse 1..v_table_list.count loop
        v_dev_table_name := v_table_list(i);
    
        SELECT constraint_name BULK COLLECT INTO dev_constraints_set
            FROM all_constraints
            WHERE owner = dev_name
                AND table_name = v_dev_table_name
                AND constraint_name NOT LIKE 'SYS%'
            ORDER BY constraint_name;
            SELECT constraint_name BULK COLLECT INTO prod_constraints_set
            FROM all_constraints
            WHERE owner = prod_name
                AND table_name = v_dev_table_name
                AND constraint_name NOT LIKE 'SYS%'
            ORDER BY constraint_name;
            
    
            FOR i IN 1..dev_constraints_set.count LOOP
                IF dev_constraints_set(i) NOT MEMBER OF prod_constraints_set THEN
                    DECLARE
                        ddl_script      CLOB;
                        constraint_type VARCHAR2(20);
                    BEGIN
                        SELECT constraint_type INTO constraint_type
                        FROM all_constraints
                        WHERE owner = dev_name
                            AND table_name = v_dev_table_name
                            AND constraint_name = dev_constraints_set(i);
                        ddl_script := dbms_metadata.get_ddl(CASE WHEN constraint_type = 'R' THEN 'REF_CONSTRAINT' ELSE 'CONSTRAINT' END, dev_constraints_set(i), dev_name);
                        ddl_script:=replace(ddl_script, dev_name, prod_name);
                        dbms_output.put_line(ddl_script);
                    END;
                END IF;
            END LOOP;
        end loop;
end;
/

call cmp_func('prod', 'dev');

call cmp_indx('prod', 'dev');

call cmp_prc('prod', 'dev');

call cmp_tbl('prod', 'dev');
/



-- Additional task
drop table dev.t1;

create table dev.t1(
    id number not null primary key,
    fk number not null
);
/
ALTER TABLE dev.t3 DROP CONSTRAINT t2_id_fk;
drop table dev.t2;

create table dev.t2(
    id number not null primary key,
    fk number not null
);
/
drop table dev.t3;

create table dev.t3(
    id number not null primary key,
    fk number not null
);
/
alter table dev.t1 add constraint t3_id_fk foreign key (fk) references dev.t3(id);
alter table dev.t3 add CONSTRAINT t2_id_fk FOREIGN KEY ( fk ) REFERENCES dev.t2 ( id );
