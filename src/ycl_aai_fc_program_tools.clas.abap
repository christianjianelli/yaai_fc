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

    METHODS check_syntax
      IMPORTING
                i_program_name    TYPE programm
      RETURNING VALUE(r_response) TYPE string.

    METHODS activate
      IMPORTING
                i_program_name    TYPE programm
      RETURNING VALUE(r_response) TYPE string.

  PROTECTED SECTION.

  PRIVATE SECTION.

    DATA _t_check_run_reports TYPE if_adt_check_run_response=>gty_check_run_reports.

    DATA _lock_handle TYPE string.

    METHODS _is_authorized
      IMPORTING
                i_program_name      TYPE programm
                i_mode              TYPE csequence DEFAULT 'SHOW'
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

    METHODS _is_active
      IMPORTING
                i_program_name     TYPE programm
      RETURNING VALUE(r_is_active) TYPE abap_bool.

    METHODS _deserialize_check_run_reports
      IMPORTING
        i_xml                TYPE xstring
      EXPORTING
        et_check_run_reports TYPE if_adt_check_run_response=>gty_check_run_reports.

    METHODS _get_line_and_column_from_uri
      IMPORTING
        i_uri    TYPE csequence
      EXPORTING
        e_line   TYPE i
        e_column TYPE i.

    METHODS _syntax_check_old
      IMPORTING
                i_program_name    TYPE programm
      RETURNING VALUE(r_response) TYPE string.

    METHODS _calculate_start_end
      IMPORTING
        i_cursor_line TYPE i
        i_lines       TYPE i
        i_max_lines   TYPE i DEFAULT 10
      EXPORTING
        e_start_line  TYPE i
        e_end_line    TYPE i.

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

  METHOD check_syntax.

    DATA lt_checkrun_objects TYPE seu_adt_check_run_objects.

    DATA ls_request  TYPE sadt_rest_request.
    DATA ls_response TYPE sadt_rest_response.

    FREE r_response.

    FREE me->_t_check_run_reports.

    ls_request-request_line-method = 'POST'.
    ls_request-request_line-uri = '/sap/bc/adt/checkruns?reporters=abapCheckRun'.
    ls_request-request_line-version = 'HTTP/1.1'.

    ls_request-header_fields = VALUE #( ( name = 'Accept'
                                          value = 'application/vnd.sap.adt.checkmessages+xml' )
                                        ( name = 'Content-Type'
                                          value = 'application/vnd.sap.adt.checkobjects+xml' )   ).

    DATA(l_program_name) = i_program_name.

    l_program_name = to_lower( condense( l_program_name ) ).

    lt_checkrun_objects = VALUE #( ( object_reference-uri = |{ mc_uri }/{ l_program_name }|
                                     version = 'inactive' ) ).

    TRY.

        CALL TRANSFORMATION sadt_check_run_objects
          SOURCE
            checkrunobjects = lt_checkrun_objects
          RESULT XML
            ls_request-message_body.

      CATCH cx_transformation_error.
        RETURN.
    ENDTRY.

    CALL FUNCTION 'SADT_REST_RFC_ENDPOINT'
      EXPORTING
        request  = ls_request
      IMPORTING
        response = ls_response.

    DATA(l_message_body) = cl_abap_codepage=>convert_from( source = ls_response-message_body ).

    me->_deserialize_check_run_reports(
      EXPORTING
        i_xml                = ls_response-message_body
      IMPORTING
        et_check_run_reports = me->_t_check_run_reports
    ).

    LOOP AT me->_t_check_run_reports ASSIGNING FIELD-SYMBOL(<ls_check_run_report>).

      LOOP AT <ls_check_run_report>-results ASSIGNING FIELD-SYMBOL(<ls_result>).

        SPLIT <ls_result>-uri AT '#start=' INTO TABLE DATA(lt_parts).

        IF lines( lt_parts ) = 2.

          SPLIT lt_parts[ 2 ] AT ',' INTO DATA(l_line) DATA(l_column).

        ENDIF.

        r_response = |{ r_response }{ <ls_result>-shorttext }{ cl_abap_char_utilities=>newline }|.

        IF l_line IS NOT INITIAL.

          r_response = |{ r_response }Line: { l_line }{ cl_abap_char_utilities=>newline }|.

          IF l_column IS NOT INITIAL.
            r_response = |{ r_response }Column: { l_column }{ cl_abap_char_utilities=>newline }|.
          ENDIF.

        ENDIF.

      ENDLOOP.

    ENDLOOP.

    IF r_response IS INITIAL.
      r_response = |The program { i_program_name } has no syntax errors.|.
      RETURN.
    ENDIF.

    DATA(l_syntax_errors_found) = |The program { i_program_name } has syntax errors.|.

    r_response = l_syntax_errors_found &&
                 cl_abap_char_utilities=>newline &&
                 cl_abap_char_utilities=>newline &&
                 r_response.

  ENDMETHOD.

  METHOD _syntax_check_old.

*    DATA lt_source TYPE ty_string_t.
*
*    DATA lt_errors TYPE STANDARD TABLE OF rslinlmsg.
*
*    DATA: l_source        TYPE string,
*          l_error_message TYPE c LENGTH 200,
*          l_error_include TYPE sy-repid,
*          l_error_line    TYPE sy-subrc,
*          l_error_offset  TYPE sy-tabix,
*          l_error_subrc   TYPE sy-subrc.
*
*    DATA(l_program_name) = i_program_name.
*
*    l_program_name = to_upper( condense( l_program_name ) ).
*
*    IF me->_is_authorized( l_program_name ) = abap_false.
*      r_response = |No authorization to read the program { i_program_name } source code.|.
*      RETURN.
*    ENDIF.
*
*    READ REPORT l_program_name INTO lt_source STATE 'I'. "Inactive version
*
*    IF lt_source IS INITIAL.
*      READ REPORT l_program_name INTO lt_source. "Active version
*    ENDIF.
*
*    CALL FUNCTION 'EDITOR_SYNTAX_CHECK'
*      EXPORTING
*        i_program       = l_program_name
*      IMPORTING
*        o_error_include = l_error_include
*        o_error_line    = l_error_line
*        o_error_message = l_error_message
*        o_error_offset  = l_error_offset
*        o_error_subrc   = l_error_subrc
*      TABLES
*        i_source        = lt_source
*        o_error_tab     = lt_errors.
*
*    IF l_error_subrc <> 0.
*
*      l_error_line = l_error_line - 2.
*
*      r_response = |Syntax error found{ cl_abap_char_utilities=>newline }{ cl_abap_char_utilities=>newline }|.
*      r_response = |{ r_response }Program: { i_program_name }{ cl_abap_char_utilities=>newline }|.
*      r_response = |{ r_response }Reported line: { l_error_line }{ cl_abap_char_utilities=>newline }|.
*      r_response = |{ r_response }Error message: { cl_abap_char_utilities=>newline }{ l_error_message }{ cl_abap_char_utilities=>newline }|.
*
*      me->_calculate_start_end(
*        EXPORTING
*          i_cursor_line = l_error_line
*          i_lines       = lines( lt_source )
*        IMPORTING
*          e_start_line  = DATA(l_start_line)
*          e_end_line    = DATA(l_end_line)
*      ).
*
*      r_response = |{ r_response }{ cl_abap_char_utilities=>newline }Code context:{ cl_abap_char_utilities=>newline }|.
*
*      LOOP AT lt_source FROM l_start_line TO l_end_line
*        ASSIGNING FIELD-SYMBOL(<l_line>).
*
*        r_response = |{ r_response }{ sy-tabix }:{ <l_line> }{ cl_abap_char_utilities=>newline }|.
*
*      ENDLOOP.
*
*    ELSE.
*
*      r_response = |No errors found in program { i_program_name }|.
*
*    ENDIF.

  ENDMETHOD.

  METHOD _is_authorized.

    "Mode ('INSERT','MODIFY','SHOW','FREE')

    r_authorized = abap_true.

    CALL FUNCTION 'RS_ACCESS_PERMISSION'
      EXPORTING
        mode                     = i_mode
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
                                          value = 'application/vnd.sap.adt.programs.programs.v2+xml' ) ).

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

  METHOD activate.

    DATA: lt_objects   TYPE STANDARD TABLE OF dwinactiv,
          ls_object    TYPE dwinactiv,
          lv_no_force  TYPE boole_d,
          lo_checklist TYPE REF TO cl_wb_checklist.

    DATA(l_program_name) = i_program_name.

    l_program_name = to_upper( condense( l_program_name ) ).

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

    DATA(l_has_errors) = abap_false.

    r_response = me->check_syntax( l_program_name ).

    LOOP AT me->_t_check_run_reports ASSIGNING FIELD-SYMBOL(<ls_check_run_report>).
      IF <ls_check_run_report>-results IS NOT INITIAL.
        l_has_errors = abap_true.
        EXIT.
      ENDIF.
    ENDLOOP.

    IF l_has_errors = abap_true.
      DATA(l_response) = |Error(s) found while activating the program { l_program_name }.{ cl_abap_char_utilities=>newline }|.
      r_response = l_response && r_response.
      RETURN.
    ENDIF.

    ls_object-object   = me->mc_object.
    ls_object-obj_name = l_program_name.

    APPEND ls_object TO lt_objects.

    CALL FUNCTION 'RS_WORKING_OBJECTS_ACTIVATE'
      EXPORTING
        suppress_enqueue       = abap_true
        suppress_corr_insert   = abap_true
        ui_decoupled           = abap_true
      IMPORTING
        p_no_force_activation  = lv_no_force
        p_checklist            = lo_checklist
      TABLES
        objects                = lt_objects
      EXCEPTIONS
        excecution_error       = 1
        cancelled              = 2
        insert_into_corr_error = 3
        OTHERS                 = 4.

    IF sy-subrc <> 0.
      " Handle activation error
      r_response = |Error while activating the program { l_program_name }.|.
      RETURN.
    ENDIF.

    lo_checklist->get_error_messages(
      IMPORTING
        p_error_tab = DATA(lt_errors)                 " Error Message Table
    ).

    LOOP AT lt_errors ASSIGNING FIELD-SYMBOL(<ls_error>).

      IF sy-tabix = 1.
        r_response = |Error(s) while activating the program { l_program_name }.{ cl_abap_char_utilities=>newline }|.
      ENDIF.

      MESSAGE ID <ls_error>-message-msgid
        TYPE <ls_error>-message-msgty
        NUMBER <ls_error>-message-msgno
        WITH <ls_error>-message-msgv1
             <ls_error>-message-msgv2
             <ls_error>-message-msgv3
             <ls_error>-message-msgv4
        INTO DATA(l_message).

      r_response = |{ r_response }{ l_message }{ cl_abap_char_utilities=>newline }|.

    ENDLOOP.

    IF me->_is_active( l_program_name ) = abap_true.

      r_response = |Program { l_program_name } activated.|.

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

  METHOD _deserialize_check_run_reports.

    TRY.

        CALL TRANSFORMATION st_adt_check_run_reports
          SOURCE XML i_xml
          RESULT checkrunreports = et_check_run_reports.

      CATCH cx_transformation_error.
        RETURN.
    ENDTRY.

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

  METHOD _is_active.

    DATA: lt_messages TYPE STANDARD TABLE OF sprot_u WITH DEFAULT KEY,
          lt_e071     TYPE STANDARD TABLE OF e071 WITH DEFAULT KEY.

    DATA ls_e071 TYPE e071.

    ls_e071-object   = mc_object.
    ls_e071-obj_name = to_upper( condense( i_program_name ) ).
    INSERT ls_e071 INTO TABLE lt_e071.

    CALL FUNCTION 'RS_INACTIVE_OBJECTS_WARNING'
      EXPORTING
        suppress_protocol         = abap_false
        with_program_includes     = abap_false
        suppress_dictionary_check = abap_false
      TABLES
        p_e071                    = lt_e071
        p_xmsg                    = lt_messages.

    r_is_active = boolc( lt_messages IS INITIAL ).

  ENDMETHOD.

  METHOD _calculate_start_end.

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

  METHOD if_oo_adt_classrun~main.

    DATA l_response TYPE string.
    DATA l_source   TYPE string.

    DATA(l_read) = abap_false.
    DATA(l_search) = abap_false.
    DATA(l_check) = abap_false.
    DATA(l_create) = abap_false.
    DATA(l_update) = abap_false.
    DATA(l_activate) = abap_true.

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

        l_response = me->check_syntax(
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

      WHEN l_activate.

        l_response = me->activate( 'ZTESTTOOL1' ).

    ENDCASE.

    out->write( l_response ).

  ENDMETHOD.

ENDCLASS.
