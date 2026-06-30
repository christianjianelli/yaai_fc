CLASS ycl_aai_fc_sql_tools DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun.

    METHODS constructor.

    METHODS execute_sql_query
      IMPORTING
                i_database_table  TYPE yde_aai_fc_database_table
                i_fieldlist       TYPE string
                i_where_clause    TYPE string
      RETURNING VALUE(r_response) TYPE string.

    METHODS execute_sql_insert
      IMPORTING
                i_database_table  TYPE yde_aai_fc_database_table
                i_values          TYPE string
      RETURNING VALUE(r_response) TYPE string.

    METHODS execute_sql_update
      IMPORTING
                i_database_table  TYPE yde_aai_fc_database_table
                i_fieldlist       TYPE string
                i_where_clause    TYPE string
      RETURNING VALUE(r_response) TYPE string.

    METHODS execute_sql_delete
      IMPORTING
                i_database_table  TYPE yde_aai_fc_database_table
                i_where_clause    TYPE string
      RETURNING VALUE(r_response) TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.

    TYPES ty_sql_operation TYPE c LENGTH 6.

    DATA: _insert_whitelist TYPE RANGE OF yde_aai_fc_database_table,
          _read_whitelist   TYPE RANGE OF yde_aai_fc_database_table,
          _update_whitelist TYPE RANGE OF yde_aai_fc_database_table,
          _delete_whitelist TYPE RANGE OF yde_aai_fc_database_table.

    METHODS _is_authorized
      IMPORTING
                i_table_name        TYPE csequence
                i_operation         TYPE ty_sql_operation
      RETURNING VALUE(r_authorized) TYPE abap_bool.

ENDCLASS.


CLASS ycl_aai_fc_sql_tools IMPLEMENTATION.

  METHOD constructor.

    SELECT sign, opti AS option, low, high
      FROM tvarvc
      WHERE name = 'YAAI_FC_SQL_INSERT_WHITELIST'
      INTO CORRESPONDING FIELDS OF TABLE @me->_insert_whitelist.

    SELECT sign, opti AS option, low, high
      FROM tvarvc
      WHERE name = 'YAAI_FC_SQL_READ_WHITELIST'
      INTO CORRESPONDING FIELDS OF TABLE @me->_read_whitelist.

    SELECT sign, opti AS option, low, high
      FROM tvarvc
      WHERE name = 'YAAI_FC_SQL_UPDATE_WHITELIST'
      INTO CORRESPONDING FIELDS OF TABLE @me->_update_whitelist.

    SELECT sign, opti AS option, low, high
      FROM tvarvc
      WHERE name = 'YAAI_FC_SQL_DELETE_WHITELIST'
      INTO CORRESPONDING FIELDS OF TABLE @me->_delete_whitelist.

  ENDMETHOD.

  METHOD _is_authorized.

    r_authorized = COND #( WHEN i_operation = 'INSERT' AND i_table_name IN me->_insert_whitelist THEN abap_true
                           WHEN i_operation = 'READ'   AND i_table_name IN me->_read_whitelist   THEN abap_true
                           WHEN i_operation = 'UPDATE' AND i_table_name IN me->_update_whitelist THEN abap_true
                           WHEN i_operation = 'DELETE' AND i_table_name IN me->_delete_whitelist THEN abap_true
                           ELSE abap_false ).

  ENDMETHOD.

  METHOD execute_sql_query.

    FIELD-SYMBOLS <lt_records> TYPE ANY TABLE.

    DATA lt_records TYPE REF TO data.

    DATA(l_table) = to_upper( condense( i_database_table ) ).

    IF me->_is_authorized( i_table_name = l_table
                           i_operation  = 'READ' ) = abap_false.

      r_response = |You are not authorized to read entries from table { l_table }.|.

      RETURN.

    ENDIF.

    TRY.

        CREATE DATA lt_records TYPE TABLE OF (l_table).

      CATCH cx_sy_create_data_error ##NO_HANDLER.

        r_response = 'Error. Tool execution failed.'.

        RETURN.

    ENDTRY.

    TRY.

        ASSIGN lt_records->* TO <lt_records>.

      CATCH cx_sy_assign_cast_illegal_cast
            cx_sy_assign_cast_unknown_type
            cx_sy_assign_out_of_range ##NO_HANDLER.

        r_response = 'Error. Tool execution failed.'.

        RETURN.

    ENDTRY.

    TRY.

        SELECT (i_fieldlist) FROM (l_table) WHERE (i_where_clause) INTO CORRESPONDING FIELDS OF TABLE @<lt_records>.

      CATCH cx_sy_dynamic_osql_error ##NO_HANDLER.

        r_response = 'Error. Tool execution failed.'.

        RETURN.

    ENDTRY.

    r_response = /ui2/cl_json=>serialize(
      EXPORTING
        data = <lt_records>
    ).

    r_response = '{"records":' && r_response && '}'.

  ENDMETHOD.

  METHOD execute_sql_insert.

    FIELD-SYMBOLS <ls_record> TYPE any.

    DATA ls_record TYPE REF TO data.

    DATA(l_table) = to_upper( condense( i_database_table ) ).

    IF me->_is_authorized( i_table_name = l_table
                           i_operation  = 'INSERT' ) = abap_false.

      r_response = |You are not authorized to insert entries into table { l_table }.|.

      RETURN.

    ENDIF.

    TRY.

        CREATE DATA ls_record TYPE (l_table).

      CATCH cx_sy_create_data_error ##NO_HANDLER.

        r_response = 'Error. Tool execution failed.'.

        RETURN.

    ENDTRY.

    TRY.

        ASSIGN ls_record->* TO <ls_record>.

      CATCH cx_sy_assign_cast_illegal_cast
            cx_sy_assign_cast_unknown_type
            cx_sy_assign_out_of_range ##NO_HANDLER.

        r_response = 'Error. Tool execution failed.'.

        RETURN.

    ENDTRY.

    /ui2/cl_json=>deserialize(
      EXPORTING
        json = i_values
      CHANGING
        data = <ls_record>
    ).

    IF <ls_record> IS INITIAL.

      r_response = 'Error. Invalid values received.'.

      RETURN.

    ENDIF.

    TRY.

        INSERT INTO (l_table) VALUES @<ls_record>.

        IF sy-dbcnt > 0.
          r_response = |Success. { sy-dbcnt } records inserted.|.
        ELSE.
          r_response = |Insert failed. { sy-dbcnt } records inserted.|.
        ENDIF.

      CATCH cx_sy_dynamic_osql_error ##NO_HANDLER.

        r_response = |Error. 0 records inserted.|.

    ENDTRY.

  ENDMETHOD.

  METHOD execute_sql_update.

    DATA l_response TYPE string.

    DATA(l_table) = to_upper( condense( i_database_table ) ).

    IF me->_is_authorized( i_table_name = l_table
                           i_operation  = 'UPDATE' ) = abap_false.

      r_response = |You are not authorized to update entries in table { l_table }.|.

      RETURN.

    ENDIF.

    TRY.

        UPDATE (l_table) SET (i_fieldlist) WHERE (i_where_clause).

        IF sy-dbcnt > 0.
          l_response = |Success. { sy-dbcnt } record(s) updated.|.
        ELSE.
          l_response = |Update failed. { sy-dbcnt } record(s) updated.|.
        ENDIF.

      CATCH cx_sy_dynamic_osql_error ##NO_HANDLER.

        r_response = 'Error. Tool execution failed.'.

        RETURN.

    ENDTRY.

  ENDMETHOD.

  METHOD execute_sql_delete.

    DATA l_response TYPE string.

    DATA(l_table) = to_upper( condense( i_database_table ) ).

    IF me->_is_authorized( i_table_name = l_table
                           i_operation  = 'DELETE' ) = abap_false.

      r_response = |You are not authorized to delete entries from table { l_table }.|.

      RETURN.

    ENDIF.

    TRY.

        DELETE FROM (l_table) WHERE (i_where_clause).

        IF sy-dbcnt > 0.
          l_response = |Success. { sy-dbcnt } record(s) deleted.|.
        ELSE.
          l_response = |Insert failed. { sy-dbcnt } record(s) deleted.|.
        ENDIF.

      CATCH cx_sy_dynamic_osql_error ##NO_HANDLER.

        r_response = 'Error. Tool execution failed.'.

        RETURN.

    ENDTRY.

  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.

    DATA l_response TYPE string.

    DATA(l_query) = abap_true.

    CASE abap_true.

      WHEN l_query.

        me->execute_sql_query(
          EXPORTING
            i_database_table = 'YAAI_API'
            i_fieldlist      = 'ID, BASE_URL'
            i_where_clause   = 'ID <> @space'
          RECEIVING
            r_response       = l_response
        ).

    ENDCASE.

    IF l_response IS NOT INITIAL.

      out->write( l_response ).

    ENDIF.

  ENDMETHOD.

ENDCLASS.
