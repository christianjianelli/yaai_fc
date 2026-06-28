CLASS ycl_aai_fc_program_tools DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun.

    CONSTANTS: mc_pgmid  TYPE e071-pgmid  VALUE 'R3TR',
               mc_object TYPE e071-object VALUE 'PROG',
               mc_uri    TYPE string      VALUE '/sap/bc/adt/programs/programs'.

    TYPES ty_string_t TYPE STANDARD TABLE OF string WITH DEFAULT KEY.

    METHODS read
      IMPORTING
                i_program_name    TYPE programm
      RETURNING VALUE(r_response) TYPE string.

    METHODS search
      IMPORTING
                i_package           TYPE packname
                i_program_name      TYPE programm OPTIONAL
                i_short_description TYPE as4text OPTIONAL
      RETURNING VALUE(r_response)   TYPE string.

    METHODS create
      IMPORTING
                i_program_name      TYPE programm
                i_short_description TYPE as4text
                i_transport_request TYPE yde_aai_fc_transport_request
                i_package           TYPE packname
      RETURNING VALUE(r_response)   TYPE string.

    METHODS update
      IMPORTING
                i_program_name      TYPE programm
                i_short_description TYPE as4text OPTIONAL
                i_transport_request TYPE yde_aai_fc_transport_request
                i_source            TYPE string
      RETURNING VALUE(r_response)   TYPE string.

    METHODS syntax_check
      IMPORTING
                i_program_name    TYPE programm
      RETURNING VALUE(r_response) TYPE string.

    METHODS calculate_start_end
      IMPORTING
        i_cursor_line TYPE i
        i_lines       TYPE i
        i_max_lines   TYPE i DEFAULT 10
      EXPORTING
        e_start_line  TYPE i
        e_end_line    TYPE i.

  PROTECTED SECTION.

  PRIVATE SECTION.

    DATA _t_check_run_reports TYPE if_adt_check_run_response=>gty_check_run_reports.

    DATA _lock_handle TYPE string.

    METHODS _is_authorized
      IMPORTING
                i_program_name      TYPE programm
      RETURNING VALUE(r_authorized) TYPE abap_bool.

    METHODS _get_properties
      IMPORTING
        i_program_name  TYPE programm
      EXPORTING
        e_error_message TYPE string
        e_s_prog_data   TYPE cl_sedi_adt_res_source=>ty_prog_data.

    METHODS _set_properties
      IMPORTING
        i_program_name      TYPE programm
        i_s_prog_data       TYPE cl_sedi_adt_res_source=>ty_prog_data
        i_transport_request TYPE yde_aai_fc_transport_request
      EXPORTING
        e_success           TYPE abap_bool
        e_error_description TYPE string.

    METHODS _get_source_code
      IMPORTING
                i_program_name  TYPE programm
      RETURNING VALUE(r_source) TYPE string.

    METHODS _lock
      IMPORTING
        i_program_name TYPE programm.

    METHODS _unlock
      IMPORTING
        i_program_name TYPE programm.

    METHODS _get_line_and_column_from_uri
      IMPORTING
        i_uri    TYPE csequence
      EXPORTING
        e_line   TYPE i
        e_column TYPE i.

ENDCLASS.



CLASS ycl_aai_fc_program_tools IMPLEMENTATION.

  METHOD read.

    DATA lt_source TYPE ty_string_t.

    DATA l_source TYPE string.

    DATA(l_program_name) = i_program_name.

    l_program_name = to_upper( condense( l_program_name ) ).

    IF me->_is_authorized( l_program_name ) = abap_false.
      r_response = |No authorization to read the program { i_program_name } source code.|.
      RETURN.
    ENDIF.

    me->_get_properties(
      EXPORTING
        i_program_name = l_program_name
      IMPORTING
        e_s_prog_data  = DATA(ls_prog_data)
    ).

    l_source = me->_get_source_code( i_program_name = l_program_name ).

    r_response = |Program: { l_program_name }|.
    r_response = |{ r_response }{ cl_abap_char_utilities=>newline }Description: { ls_prog_data-description }|.
    r_response = |{ r_response }{ cl_abap_char_utilities=>newline }|.
    r_response = |{ r_response }{ cl_abap_char_utilities=>newline }```abap|.
    r_response = |{ r_response }{ cl_abap_char_utilities=>newline }{ l_source }|.
    r_response = |{ r_response }{ cl_abap_char_utilities=>newline }```|.

  ENDMETHOD.

  METHOD search.

    DATA: l_program           TYPE string,
          l_short_description TYPE string.

    CLEAR r_response.

    DATA(l_package) = i_package.

    l_package = condense( to_upper( l_package ) ).

    SELECT pgmid, object, obj_name, devclass, masterlang
      FROM tadir
      WHERE pgmid = @mc_pgmid
        AND object = @mc_object
        AND devclass = @l_package
      INTO TABLE @DATA(lt_tadir).                       "#EC CI_GENBUFF

    IF sy-subrc <> 0.
      r_response = |No program found in package { l_package }.|.
      RETURN.
    ENDIF.

    l_program = |*{ i_program_name }*|.

    l_short_description = |*{ i_short_description }*|.

    LOOP AT lt_tadir ASSIGNING FIELD-SYMBOL(<ls_tadir>).

      IF l_program IS NOT INITIAL.

        IF NOT <ls_tadir>-obj_name CP l_program.
          CONTINUE.
        ENDIF.

      ENDIF.

      IF r_response IS NOT INITIAL.
        r_response = |{ r_response }{ cl_abap_char_utilities=>newline }|.
      ENDIF.

      SELECT SINGLE name, sprsl, text
        FROM trdirt
        INTO @DATA(ls_trdirt)
        WHERE name = @<ls_tadir>-obj_name
          AND sprsl = @sy-langu.

      IF i_short_description IS NOT INITIAL.

        IF NOT ls_trdirt-text CP l_short_description.
          CONTINUE.
        ENDIF.

      ENDIF.

      r_response = |{ r_response }Program: { <ls_tadir>-obj_name }{ cl_abap_char_utilities=>newline }|.
      r_response = |{ r_response }Description: { ls_trdirt-text }{ cl_abap_char_utilities=>newline }|.

    ENDLOOP.

    IF r_response IS INITIAL.
      r_response = |No program found in package { l_package }.|.
    ENDIF.

  ENDMETHOD.

  METHOD create.

    DATA: ls_request   TYPE sadt_rest_request,
          ls_response  TYPE sadt_rest_response,
          ls_prog_data TYPE cl_sedi_adt_res_source=>ty_prog_data,
          ls_exc_data  TYPE sadt_exception.

    DATA l_langu TYPE t002-laiso.

    DATA(l_transport_request) = to_upper( condense( i_transport_request ) ).

    ls_request-request_line-method = 'POST' ##NO_TEXT.
    ls_request-request_line-uri = |{ mc_uri }?corrNr={ l_transport_request }|.
    ls_request-request_line-version = 'HTTP/1.1' ##NO_TEXT.

    ls_request-header_fields = VALUE #( ( name = 'Accept'
                                          value = 'application/vnd.sap.adt.checkmessages+xml' )
                                        ( name = 'Content-Type'
                                          value = 'application/vnd.sap.adt.programs.programs.v2+xml' ) ).

    ls_prog_data-description = i_short_description.
    ls_prog_data-language = sy-langu.
    ls_prog_data-name = to_upper( condense( i_program_name ) ).
    ls_prog_data-type = 'PROG/P' ##NO_TEXT.
    ls_prog_data-responsible = sy-uname.
    ls_prog_data-master_system = sy-sysid.
    ls_prog_data-master_language = sy-langu.
    ls_prog_data-package_ref-name = to_upper( condense( i_package ) ).

    TRY.

        CALL TRANSFORMATION sedi_adt_program
          SOURCE
            prog_data = ls_prog_data
          RESULT XML
            ls_request-message_body.

      CATCH cx_transformation_error.

        r_response = |An error occured while creating the program { i_program_name }.|.

        RETURN.
    ENDTRY.

    CALL FUNCTION 'SADT_REST_RFC_ENDPOINT'
      EXPORTING
        request  = ls_request
      IMPORTING
        response = ls_response.

    IF ls_response-message_body IS NOT INITIAL.

      TRY.

          SELECT SINGLE laiso FROM t002 INTO @l_langu WHERE spras = @sy-langu.

          CALL TRANSFORMATION sadt_exception
            SOURCE XML ls_response-message_body
            RESULT exception_data = ls_exc_data
                   langu          = l_langu.

        CATCH cx_transformation_error ##NO_HANDLER.
      ENDTRY.

    ENDIF.

    IF ls_exc_data-message IS NOT INITIAL.

      r_response = ls_exc_data-message.

      RETURN.

    ENDIF.

    r_response = |Program { i_program_name } created successfully!|.

  ENDMETHOD.

  METHOD update.

    DATA: ls_request  TYPE sadt_rest_request,
          ls_response TYPE sadt_rest_response,
          ls_exc_data TYPE sadt_exception.

    DATA l_langu TYPE t002-laiso.

    DATA(l_transport_request) = to_upper( condense( i_transport_request ) ).

    DATA(l_program_name) = i_program_name.

    l_program_name =  to_upper( condense( l_program_name ) ).

    SELECT SINGLE pgmid, object, obj_name, devclass, masterlang
      FROM tadir
      WHERE pgmid = @mc_pgmid
        AND object = @mc_object
        AND obj_name = @l_program_name
      INTO @DATA(ls_tadir).

    IF sy-subrc <> 0.
      r_response = |Program { l_program_name } not found.|.
      RETURN.
    ENDIF.

    me->_lock( l_program_name ).

    ls_request-request_line-method = 'PUT'.
    ls_request-request_line-uri = |{ mc_uri }/{ l_program_name }/source/main?lockHandle={ me->_lock_handle }&corrNr={ l_transport_request }|.
    ls_request-request_line-version = 'HTTP/1.1'.

    ls_request-header_fields = VALUE #( ( name = 'Accept'
                                          value = 'text/plain' )

                                        ( name = 'Content-Type'
                                          value = 'text/plain' ) ).

    ls_request-message_body = cl_abap_codepage=>convert_to( source = i_source ).

    CALL FUNCTION 'SADT_REST_RFC_ENDPOINT'
      EXPORTING
        request  = ls_request
      IMPORTING
        response = ls_response.

    IF ls_response-message_body IS NOT INITIAL.

      TRY.

          SELECT SINGLE laiso FROM t002 INTO @l_langu WHERE spras = @sy-langu.

          CALL TRANSFORMATION sadt_exception
            SOURCE XML ls_response-message_body
            RESULT exception_data = ls_exc_data
                   langu          = l_langu.

        CATCH cx_transformation_error ##NO_HANDLER.
      ENDTRY.

    ENDIF.

    IF ls_exc_data-message IS NOT INITIAL.

      me->_unlock( i_program_name ).

      r_response = ls_exc_data-message.

      RETURN.

    ENDIF.

    IF i_short_description IS NOT INITIAL.

      me->_get_properties(
        EXPORTING
          i_program_name = i_program_name
        IMPORTING
          e_s_prog_data  = DATA(ls_prog_data)
      ).

      ls_prog_data-description = i_short_description.

      me->_set_properties(
        EXPORTING
          i_program_name      = i_program_name
          i_transport_request = i_transport_request
          i_s_prog_data       = ls_prog_data
        IMPORTING
          e_error_description = DATA(l_error_description)
          e_success           = DATA(l_properties_updated)
      ).

      IF l_properties_updated = abap_false.

        r_response = |Program { i_program_name } source code updated but the description was not.|.

        IF l_error_description IS NOT INITIAL.
          r_response = |{ r_response }Error: { l_error_description }|.
        ENDIF.

        me->_unlock( i_program_name ).

        RETURN.

      ENDIF.

    ENDIF.

    me->_unlock( i_program_name ).

    r_response = |Program { i_program_name } updated successfully!|.

  ENDMETHOD.

  METHOD syntax_check.

    DATA lt_source TYPE ty_string_t.

    DATA lt_errors TYPE STANDARD TABLE OF rslinlmsg.

    DATA: l_source        TYPE string,
          l_error_message TYPE c LENGTH 200,
          l_error_include TYPE sy-repid,
          l_error_line    TYPE sy-subrc,
          l_error_offset  TYPE sy-tabix,
          l_error_subrc   TYPE sy-subrc.

    DATA(l_program_name) = i_program_name.

    l_program_name = to_upper( condense( l_program_name ) ).

    IF me->_is_authorized( l_program_name ) = abap_false.
      r_response = |No authorization to read the program { i_program_name } source code.|.
      RETURN.
    ENDIF.

    READ REPORT l_program_name INTO lt_source STATE 'I'. "Inactive version

    IF lt_source IS INITIAL.
      READ REPORT l_program_name INTO lt_source. "Active version
    ENDIF.

    CALL FUNCTION 'EDITOR_SYNTAX_CHECK'
      EXPORTING
        i_program       = l_program_name
      IMPORTING
        o_error_include = l_error_include
        o_error_line    = l_error_line
        o_error_message = l_error_message
        o_error_offset  = l_error_offset
        o_error_subrc   = l_error_subrc
      TABLES
        i_source        = lt_source
        o_error_tab     = lt_errors.

    IF l_error_subrc <> 0.

      l_error_line = l_error_line - 2.

      r_response = |Syntax error found{ cl_abap_char_utilities=>newline }{ cl_abap_char_utilities=>newline }|.
      r_response = |{ r_response }Program: { i_program_name }{ cl_abap_char_utilities=>newline }|.
      r_response = |{ r_response }Reported line: { l_error_line }{ cl_abap_char_utilities=>newline }|.
      r_response = |{ r_response }Error message: { cl_abap_char_utilities=>newline }{ l_error_message }{ cl_abap_char_utilities=>newline }|.

      me->calculate_start_end(
        EXPORTING
          i_cursor_line = l_error_line
          i_lines       = lines( lt_source )
        IMPORTING
          e_start_line  = DATA(l_start_line)
          e_end_line    = DATA(l_end_line)
      ).

      r_response = |{ r_response }{ cl_abap_char_utilities=>newline }Code context:{ cl_abap_char_utilities=>newline }|.

      LOOP AT lt_source FROM l_start_line TO l_end_line
        ASSIGNING FIELD-SYMBOL(<l_line>).

        r_response = |{ r_response }{ sy-tabix }:{ <l_line> }{ cl_abap_char_utilities=>newline }|.

      ENDLOOP.

    ELSE.

      r_response = |No errors found in program { i_program_name }|.

    ENDIF.

  ENDMETHOD.

  METHOD _is_authorized.

    r_authorized = abap_true.

    CALL FUNCTION 'RS_ACCESS_PERMISSION'
      EXPORTING
        mode                     = 'SHOW'
        object                   = i_program_name
        object_class             = mc_object
        suppress_corr_check      = abap_true
        suppress_language_check  = abap_true
        suppress_extend_dialog   = abap_true
      EXCEPTIONS
        canceled_in_corr         = 1
        enqueued_by_user         = 2
        enqueue_system_failure   = 3
        illegal_parameter_values = 4
        locked_by_author         = 5
        no_modify_permission     = 6
        no_show_permission       = 7
        permission_failure       = 8
        request_language_denied  = 9
        OTHERS                   = 10.

    IF sy-subrc <> 0.
      r_authorized = abap_false.
    ENDIF.

  ENDMETHOD.

  METHOD _get_properties.

    DATA: ls_request  TYPE sadt_rest_request,
          ls_response TYPE sadt_rest_response,
          ls_exc_data TYPE sadt_exception.

    DATA l_langu TYPE t002-laiso.

    CLEAR e_s_prog_data.

    DATA(l_program_name) = to_lower( condense( i_program_name ) ).

    ls_request-request_line-method = 'GET'.
    ls_request-request_line-uri = |{ me->mc_uri }/{ l_program_name }|.
    ls_request-request_line-version = 'HTTP/1.1'.

    ls_request-header_fields = VALUE #( ( name = 'Accept'
                                          value = 'application/vnd.sap.adt.programs.programs.v2+xml' ) ).

    CALL FUNCTION 'SADT_REST_RFC_ENDPOINT'
      EXPORTING
        request  = ls_request
      IMPORTING
        response = ls_response.

    IF ls_response-message_body IS INITIAL.
      RETURN.
    ENDIF.

    TRY.

        CALL TRANSFORMATION sedi_adt_program
          SOURCE XML ls_response-message_body
          RESULT prog_data = e_s_prog_data.

      CATCH cx_transformation_error ##NO_HANDLER.
    ENDTRY.

    IF ls_response-message_body IS NOT INITIAL.

      TRY.

          SELECT SINGLE laiso FROM t002 INTO @l_langu WHERE spras = @sy-langu.

          CALL TRANSFORMATION sadt_exception
            SOURCE XML ls_response-message_body
            RESULT exception_data = ls_exc_data
                   langu          = l_langu.

        CATCH cx_transformation_error ##NO_HANDLER.
      ENDTRY.

    ENDIF.

    IF ls_exc_data-message IS NOT INITIAL.
      e_error_message = ls_exc_data-message.
    ENDIF.

  ENDMETHOD.

  METHOD _set_properties.

    DATA: ls_request  TYPE sadt_rest_request,
          ls_response TYPE sadt_rest_response,
          ls_exc_data TYPE sadt_exception.

    DATA l_langu TYPE t002-laiso.

    CLEAR: e_error_description,
           e_success.

    DATA(l_program_name) = to_lower( condense( i_program_name ) ).
    DATA(l_transport_request) = to_upper( condense( i_transport_request ) ).

    ls_request-request_line-method = 'PUT'.
    ls_request-request_line-uri = |{ me->mc_uri }/{ l_program_name }?lockHandle={ me->_lock_handle }&corrNr={ l_transport_request }|.
    ls_request-request_line-version = 'HTTP/1.1'.

    ls_request-header_fields = VALUE #( ( name = 'Accept'
                                          value = 'application/vnd.sap.adt.checkmessages+xml' )

                                        ( name = 'Content-Type'
                                          value = 'application/vnd.sap.adt.oo.classes.v2+xml' ) ).

    TRY.

        CALL TRANSFORMATION sedi_adt_program
          SOURCE prog_data = i_s_prog_data
          RESULT XML ls_request-message_body.

      CATCH cx_transformation_error ##NO_HANDLER.
    ENDTRY.

    CALL FUNCTION 'SADT_REST_RFC_ENDPOINT'
      EXPORTING
        request  = ls_request
      IMPORTING
        response = ls_response.

    IF ls_response-message_body IS INITIAL.

      e_success = abap_true.

      RETURN.

    ELSE.

      e_success = abap_false.

      TRY.

          SELECT SINGLE laiso FROM t002 INTO @l_langu WHERE spras = @sy-langu.

          CALL TRANSFORMATION sadt_exception
            SOURCE XML ls_response-message_body
            RESULT exception_data = ls_exc_data
                   langu          = l_langu.

          e_error_description = ls_exc_data-message.

        CATCH cx_transformation_error ##NO_HANDLER.
      ENDTRY.

    ENDIF.

  ENDMETHOD.

  METHOD _get_source_code.

    DATA: ls_request  TYPE sadt_rest_request,
          ls_response TYPE sadt_rest_response.

    DATA(l_program_name) = to_lower( condense( i_program_name ) ).

    ls_request-request_line-method = 'GET'.
    ls_request-request_line-uri = |{ me->mc_uri }/{ l_program_name }/source/main|.
    ls_request-request_line-version = 'HTTP/1.1'.

    ls_request-header_fields = VALUE #( ( name = 'Accept'
                                          value = 'text/plain' ) ).

    CALL FUNCTION 'SADT_REST_RFC_ENDPOINT'
      EXPORTING
        request  = ls_request
      IMPORTING
        response = ls_response.

    r_source = cl_abap_codepage=>convert_from( source = ls_response-message_body ).

  ENDMETHOD.

  METHOD calculate_start_end.

    " If the total number of lines is less than or equal to the max lines,
    " the range is simply the entire file.
    IF i_lines <= i_max_lines.
      e_start_line = 1.
      e_end_line = i_lines.
      RETURN.
    ENDIF.

    " Calculate how many lines to take before and after the cursor.
    " DIV performs integer division (it discards the remainder), which is
    " equivalent to floor().
    DATA(l_lines_before) = ( i_max_lines - 1 ) DIV 2.
    DATA(l_lines_after)  = i_max_lines - 1 - l_lines_before.

    " Calculate the initial ideal start and end lines.
    DATA(l_start_line) = i_cursor_line - l_lines_before.
    DATA(l_end_line)   = i_cursor_line + l_lines_after.

    " Adjust the range if it goes out of the file's boundaries.
    IF l_start_line < 1.
      " CASE 1: Cursor is near the beginning of the file.
      e_start_line = 1.
      e_end_line = i_max_lines.
    ELSEIF l_end_line > i_lines.
      " CASE 2: Cursor is near the end of the file.
      e_end_line = i_lines.
      e_start_line = i_lines - i_max_lines + 1.
    ELSE.
      " CASE 3: The ideal range is valid and within boundaries.
      e_start_line = l_start_line.
      e_end_line = l_end_line.
    ENDIF.

  ENDMETHOD.

  METHOD _lock.

    DATA: ls_request     TYPE sadt_rest_request,
          ls_response    TYPE sadt_rest_response,
          ls_lock_result TYPE sadt_object_lock_result2.

    DATA(l_program_name) = to_lower( condense( i_program_name ) ).

    ls_request-request_line-method = 'POST' ##NO_TEXT.
    ls_request-request_line-uri = |{ me->mc_uri }/{ l_program_name }?_action=LOCK&accessMode=MODIFY|.
    ls_request-request_line-version = 'HTTP/1.1' ##NO_TEXT.

    ls_request-header_fields = VALUE #( ( name = 'Accept'
                                          value = 'application/vnd.sap.as+xml;charset=UTF-8;dataname=com.sap.adt.lock.result2;q=0.9' ) ).

    CALL FUNCTION 'SADT_REST_RFC_ENDPOINT'
      EXPORTING
        request  = ls_request
      IMPORTING
        response = ls_response.

    TRY.

        CALL TRANSFORMATION sadt_id
          SOURCE XML ls_response-message_body
          RESULT data = ls_lock_result.

      CATCH cx_transformation_error.
        RETURN.
    ENDTRY.

    me->_lock_handle = ls_lock_result-lock_handle.

  ENDMETHOD.

  METHOD _unlock.

    DATA: ls_request  TYPE sadt_rest_request,
          ls_response TYPE sadt_rest_response.

    DATA(l_program_name) = to_lower( condense( i_program_name ) ).

    ls_request-request_line-method = 'POST' ##NO_TEXT.
    ls_request-request_line-uri = |{ me->mc_uri }/{ l_program_name }?_action=UNLOCK&lockHandle={ me->_lock_handle }| ##NO_TEXT.
    ls_request-request_line-version = 'HTTP/1.1' ##NO_TEXT.

    CALL FUNCTION 'SADT_REST_RFC_ENDPOINT'
      EXPORTING
        request  = ls_request
      IMPORTING
        response = ls_response.

  ENDMETHOD.

  METHOD _get_line_and_column_from_uri.

    DATA: l_line   TYPE string,
          l_column TYPE string.

    e_line = 0.
    e_column = 0.

    SPLIT i_uri AT '#start=' INTO TABLE DATA(lt_parts).

    IF lines( lt_parts ) = 2.

      SPLIT lt_parts[ 2 ] AT ',' INTO l_line l_column.

      l_line = condense( l_line ).

      l_column = condense( l_column ).

      IF l_line CO '0123456789'.
        e_line = l_line.
      ENDIF.

      IF l_column CO '0123456789'.
        e_column = l_column.
      ENDIF.

    ENDIF.

  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.

    DATA l_response TYPE string.
    DATA l_source   TYPE string.

    DATA(l_read) = abap_false.
    DATA(l_search) = abap_false.
    DATA(l_check) = abap_false.
    DATA(l_create) = abap_false.
    DATA(l_update) = abap_true.

    CASE abap_true.

      WHEN l_read.

        l_response = me->read(
          EXPORTING
            i_program_name = 'ZTESTTOOL1'
        ).

      WHEN l_search.

        l_response = me->search(
                       i_package           = 'Z001'
*                       i_program_name      =
*                       i_short_description =
                     ).

      WHEN l_check.

        l_response = me->syntax_check(
          EXPORTING
            i_program_name = 'ZCHRJS00'
        ).

      WHEN l_create.

        l_response = me->create( i_program_name      = 'ZTESTTOOL1'
                                 i_short_description = 'Test create tool'
                                 i_transport_request = 'NPLK900125'
                                 i_package           = 'Z001'
                               ).

      WHEN l_update.

        l_source = '*&---------------------------------------------------------------------*'.
        l_source = |{ l_source }{ cl_abap_char_utilities=>newline }*& Report ZTESTTOOL1|.
        l_source = |{ l_source }{ cl_abap_char_utilities=>newline }*&---------------------------------------------------------------------*|.
        l_source = |{ l_source }{ cl_abap_char_utilities=>newline }*&|.
        l_source = |{ l_source }{ cl_abap_char_utilities=>newline }*&---------------------------------------------------------------------*|.
        l_source = |{ l_source }{ cl_abap_char_utilities=>newline }REPORT ztesttool1.|.
        l_source = |{ l_source }{ cl_abap_char_utilities=>newline }START-OF-SELECTION.|.
        l_source = |{ l_source }{ cl_abap_char_utilities=>newline } IF 1 = 3.{ cl_abap_char_utilities=>newline }{ cl_abap_char_utilities=>newline }  ENDIF.|.

        l_response = me->update( i_program_name      = 'ZTESTTOOL1'
                                 i_short_description = 'Test update tool 2'
                                 i_transport_request = 'NPLK900125'
                                 i_source            = l_source
                               ).

    ENDCASE.

    out->write( l_response ).

  ENDMETHOD.

ENDCLASS.
