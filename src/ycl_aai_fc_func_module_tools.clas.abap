CLASS ycl_aai_fc_func_module_tools DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun.

    CONSTANTS: mc_pgmid           TYPE e071-pgmid  VALUE 'R3TR',
               mc_object          TYPE e071-object VALUE 'FUGR',
               mc_object_function TYPE e071-object VALUE 'FUNC',
               mc_uri             TYPE string      VALUE '/sap/bc/adt/functions/groups/&1/fmodules'.

    TYPES ty_string_t TYPE STANDARD TABLE OF string WITH DEFAULT KEY.

    METHODS read
      IMPORTING
                i_function_module TYPE rs38l_fnam
      RETURNING VALUE(r_response) TYPE string.

    METHODS search
      IMPORTING
                i_package           TYPE packname
                i_function_module   TYPE rs38l_fnam OPTIONAL
                i_short_description TYPE as4text OPTIONAL
      RETURNING VALUE(r_response)   TYPE string.

    METHODS create
      IMPORTING
                i_function_module   TYPE rs38l_fnam
                i_short_description TYPE as4text
                i_function_group    TYPE rs38l_area
                i_transport_request TYPE yde_aai_fc_transport_request
      RETURNING VALUE(r_response)   TYPE string.

    METHODS update
      IMPORTING
                i_function_module   TYPE rs38l_fnam
                i_short_description TYPE as4text OPTIONAL
                i_transport_request TYPE yde_aai_fc_transport_request
                i_source            TYPE string
      RETURNING VALUE(r_response)   TYPE string.

    METHODS check_syntax
      IMPORTING
                i_function_module TYPE rs38l_fnam
      RETURNING VALUE(r_response) TYPE string.

    METHODS activate
      IMPORTING
                i_function_module TYPE rs38l_fnam
      RETURNING VALUE(r_response) TYPE string.

  PROTECTED SECTION.

  PRIVATE SECTION.

    DATA _t_check_run_reports TYPE if_adt_check_run_response=>gty_check_run_reports.

    DATA _lock_handle TYPE string.

    METHODS _is_authorized
      IMPORTING
                i_function_module   TYPE rs38l_fnam
                i_mode              TYPE csequence DEFAULT 'SHOW'
      RETURNING VALUE(r_authorized) TYPE abap_bool.

    METHODS _get_source_code
      IMPORTING
                i_function_module TYPE rs38l_fnam
      RETURNING VALUE(r_source)   TYPE string.

    METHODS _get_properties
      IMPORTING
        i_function_module TYPE rs38l_fnam
      EXPORTING
        e_error_message   TYPE string
        e_s_func_data     TYPE cl_fb_adt_res_func_base=>func_data_xml.

    METHODS _set_properties
      IMPORTING
        i_function_module   TYPE rs38l_fnam
        i_s_func_data       TYPE cl_fb_adt_res_func_base=>func_data_xml
        i_transport_request TYPE yde_aai_fc_transport_request
      EXPORTING
        e_success           TYPE abap_bool
        e_error_description TYPE string.

    METHODS _get_function_group
      IMPORTING
                i_function_module       TYPE rs38l_fnam
      RETURNING VALUE(r_function_group) TYPE rs38l_area.

    METHODS _lock
      IMPORTING
        i_function_module TYPE rs38l_fnam.

    METHODS _unlock
      IMPORTING
        i_function_module TYPE rs38l_fnam.

    METHODS _is_active
      IMPORTING
                i_function_module  TYPE rs38l_fnam
      RETURNING VALUE(r_is_active) TYPE abap_bool.

    METHODS _deserialize_check_run_reports
      IMPORTING
        i_xml                TYPE xstring
      EXPORTING
        et_check_run_reports TYPE if_adt_check_run_response=>gty_check_run_reports.

ENDCLASS.



CLASS ycl_aai_fc_func_module_tools IMPLEMENTATION.

  METHOD read.

    TYPES: BEGIN OF ty_function,
             funcname          TYPE rs38l_fnam,
             global_flag       TYPE rs38l-global,
             remote_call       TYPE rs38l-remote,
             update_task       TYPE rs38l-utask,
             short_text        TYPE tftit-stext,
             rfcscope          TYPE c LENGTH 1,
             rfcvers           TYPE c LENGTH 10,
             import            TYPE STANDARD TABLE OF rsimp WITH DEFAULT KEY,
             changing          TYPE STANDARD TABLE OF rscha WITH DEFAULT KEY,
             export            TYPE STANDARD TABLE OF rsexp WITH DEFAULT KEY,
             tables            TYPE STANDARD TABLE OF rstbl WITH DEFAULT KEY,
             exception         TYPE STANDARD TABLE OF rsexc WITH DEFAULT KEY,
             documentation     TYPE STANDARD TABLE OF rsfdo WITH DEFAULT KEY,
             exception_classes TYPE abap_bool,
           END OF ty_function.

    DATA: lt_source     TYPE TABLE OF rssource,
          lt_new_source TYPE rsfb_source.

    DATA ls_function TYPE ty_function.

    DATA l_source TYPE string.

    DATA(l_function_module) = i_function_module.

    l_function_module = condense( to_upper( i_function_module ) ).

    IF me->_is_authorized( i_function_module ) = abap_false.
      r_response = |No authorization to read the function module { i_function_module } source code.|.
      RETURN.
    ENDIF.

    CALL FUNCTION 'RPY_FUNCTIONMODULE_READ_NEW'
      EXPORTING
        functionname       = l_function_module
      IMPORTING
        global_flag        = ls_function-global_flag
        remote_call        = ls_function-remote_call
        update_task        = ls_function-update_task
        short_text         = ls_function-short_text
      TABLES
        import_parameter   = ls_function-import
        changing_parameter = ls_function-changing
        export_parameter   = ls_function-export
        tables_parameter   = ls_function-tables
        exception_list     = ls_function-exception
        documentation      = ls_function-documentation
        source             = lt_source
      CHANGING
        new_source         = lt_new_source
      EXCEPTIONS
        error_message      = 1
        function_not_found = 2
        invalid_name       = 3
        OTHERS             = 4.

    IF sy-subrc <> 0.
      r_response = |Function module { i_function_module } not found.|.
      RETURN.
    ENDIF.


    IF lt_new_source[] IS NOT INITIAL.

      LOOP AT lt_new_source ASSIGNING FIELD-SYMBOL(<l_new_source>).

        IF l_source IS INITIAL.
          l_source = <l_new_source> && cl_abap_char_utilities=>newline.
        ELSE.
          l_source = l_source  && <l_new_source> && cl_abap_char_utilities=>newline.
        ENDIF.

      ENDLOOP.

    ELSE.

      LOOP AT lt_source ASSIGNING FIELD-SYMBOL(<ls_source>).

        IF l_source IS INITIAL.
          l_source = <ls_source>-line && cl_abap_char_utilities=>newline.
        ELSE.
          l_source = l_source  && <ls_source>-line && cl_abap_char_utilities=>newline.
        ENDIF.

      ENDLOOP.

    ENDIF.

    r_response = | - **Function Module**: { l_function_module }{ cl_abap_char_utilities=>newline }{ cl_abap_char_utilities=>newline }|.

    IF ls_function-remote_call IS INITIAL AND ls_function-update_task IS INITIAL.

      r_response = |{ r_response } - **Type**: Regular Function Module{ cl_abap_char_utilities=>newline }{ cl_abap_char_utilities=>newline }|.

    ELSEIF ls_function-remote_call IS NOT INITIAL.

      r_response = |{ r_response } - **Type**: Remote-Enabled Module (RFC){ cl_abap_char_utilities=>newline }{ cl_abap_char_utilities=>newline }|.

    ELSEIF ls_function-update_task IS NOT INITIAL.

      r_response = |{ r_response } - **Type**: Update Module{ cl_abap_char_utilities=>newline }{ cl_abap_char_utilities=>newline }|.

    ENDIF.

    r_response = |{ r_response } - **Short text**: { ls_function-short_text }{ cl_abap_char_utilities=>newline }{ cl_abap_char_utilities=>newline }|.

    r_response = |{ r_response }{ cl_abap_char_utilities=>newline }```abap|.

    r_response = |{ r_response }{ cl_abap_char_utilities=>newline }{ l_source }```|.

  ENDMETHOD.

  METHOD search.

    DATA: l_function_module   TYPE string,
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
      r_response = |No function module found in package { l_package }.|.
      RETURN.
    ENDIF.

    LOOP AT lt_tadir ASSIGNING FIELD-SYMBOL(<ls_tadir>).
      <ls_tadir>-obj_name = 'SAPL' && <ls_tadir>-obj_name.
    ENDLOOP.

    SELECT funcname, pname
      FROM tfdir
      FOR ALL ENTRIES IN @lt_tadir
      WHERE pname = @lt_tadir-obj_name
      INTO TABLE @DATA(lt_tfdir).                       "#EC CI_GENBUFF

    SORT lt_tfdir BY pname.

    IF lt_tfdir IS NOT INITIAL.

      SELECT spras, funcname, stext
        FROM tftit
        FOR ALL ENTRIES IN @lt_tfdir
        WHERE spras = @sy-langu
          AND funcname = @lt_tfdir-funcname
        ORDER BY PRIMARY KEY
        INTO TABLE @DATA(lt_tftit).

    ENDIF.

    l_function_module = |*{ i_function_module }*|.

    l_short_description = |*{ i_short_description }*|.

    LOOP AT lt_tadir ASSIGNING <ls_tadir>.

      READ TABLE lt_tfdir TRANSPORTING NO FIELDS
        WITH KEY pname = <ls_tadir>-obj_name
        BINARY SEARCH.

      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      DATA(l_tabix) = sy-tabix.

      LOOP AT lt_tfdir ASSIGNING FIELD-SYMBOL(<ls_tfdir>) FROM l_tabix.

        IF <ls_tfdir>-pname <> <ls_tadir>-obj_name.
          EXIT.
        ENDIF.

        IF r_response IS NOT INITIAL.
          r_response = |{ r_response }{ cl_abap_char_utilities=>newline }|.
        ENDIF.

        r_response = |{ r_response }Function Module: { <ls_tfdir>-funcname }{ cl_abap_char_utilities=>newline }|.

        READ TABLE lt_tftit ASSIGNING FIELD-SYMBOL(<ls_tftit>)
          WITH KEY spras = sy-langu
                   funcname =  <ls_tfdir>-funcname
          BINARY SEARCH.

        IF sy-subrc = 0.
          r_response = |{ r_response }Description: { <ls_tftit>-stext }{ cl_abap_char_utilities=>newline }|.
        ELSE.

          SELECT spras, funcname, stext
            FROM tftit
            WHERE funcname = @<ls_tfdir>-funcname
            INTO @DATA(ls_tftit)
            UP TO 1 ROWS.                               "#EC CI_GENBUFF
          ENDSELECT.

          r_response = |{ r_response }Description: { ls_tftit-stext }{ cl_abap_char_utilities=>newline }|.

        ENDIF.

      ENDLOOP.

    ENDLOOP.

  ENDMETHOD.

  METHOD create.

    DATA: ls_request   TYPE sadt_rest_request,
          ls_response  TYPE sadt_rest_response,
          ls_func_data TYPE cl_fb_adt_res_func_base=>func_data_xml,
          ls_exc_data  TYPE sadt_exception.

    DATA l_langu TYPE t002-laiso.

    DATA(l_function_group) = to_lower( condense( i_function_group ) ).

    DATA(l_transport_request) = to_upper( condense( i_transport_request ) ).

    ls_request-request_line-method = 'POST' ##NO_TEXT.
    ls_request-request_line-uri = |{ mc_uri }?corrNr={ l_transport_request }|.
    ls_request-request_line-version = 'HTTP/1.1' ##NO_TEXT.

    REPLACE '&1' IN ls_request-request_line-uri WITH l_function_group.

    ls_request-header_fields = VALUE #( ( name = 'Accept'
                                          value = 'application/vnd.sap.adt.checkmessages+xml' )
                                        ( name = 'Content-Type'
                                          value = 'application/vnd.sap.adt.functions.fmodules.v2+xml' ) ).

    ls_func_data-description = i_short_description.
    ls_func_data-language = sy-langu.
    ls_func_data-name = to_upper( condense( i_function_module ) ).
    ls_func_data-type = 'FUGR/FF' ##NO_TEXT.
*    ls_func_data-responsible = sy-uname.
*    ls_func_data-master_system = sy-sysid.
*    ls_func_data-master_language = sy-langu.
*    ls_func_data-package_ref-name = to_upper( condense( i_package ) ).

    TRY.

        CALL TRANSFORMATION st_fb_adt_func
          SOURCE
            func_data = ls_func_data
          RESULT XML
            ls_request-message_body.

      CATCH cx_transformation_error.

        r_response = |An error occured while creating the function module { i_function_module }.|.

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

    r_response = |Function Module { i_function_module } created successfully!|.

  ENDMETHOD.

  METHOD update.

    DATA: ls_request  TYPE sadt_rest_request,
          ls_response TYPE sadt_rest_response,
          ls_exc_data TYPE sadt_exception.

    DATA l_langu TYPE t002-laiso.

    DATA(l_function_module) = to_upper( condense( i_function_module ) ).

    SELECT SINGLE @abap_true
      FROM tfdir
      WHERE funcname = @l_function_module
      INTO @DATA(l_exists).

    IF sy-subrc <> 0.
      r_response = |Function Module { i_function_module } not found.|.
      RETURN.
    ENDIF.

    DATA(l_function_group) = me->_get_function_group( i_function_module ).

    DATA(l_function_group_name) = to_lower( condense( l_function_group ) ).

    DATA(l_transport_request) = to_upper( condense( i_transport_request ) ).

    me->_lock( i_function_module ).

    ls_request-request_line-method = 'PUT'.
    ls_request-request_line-uri = |{ mc_uri }/{ to_lower( l_function_module ) }/source/main?lockHandle={ me->_lock_handle }&corrNr={ l_transport_request }|.
    ls_request-request_line-version = 'HTTP/1.1'.

    REPLACE '&1' IN ls_request-request_line-uri WITH l_function_group_name.

    ls_request-header_fields = VALUE #( ( name = 'Accept'
                                          value = 'text/plain, application/vnd.sap.adt.checkmessages+xml' )

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

      me->_unlock( i_function_module ).

      r_response = ls_exc_data-message.

      RETURN.

    ENDIF.

    IF i_short_description IS NOT INITIAL.

      me->_get_properties(
        EXPORTING
          i_function_module = i_function_module
        IMPORTING
          e_s_func_data = DATA(ls_func_data)
      ).

      ls_func_data-description = i_short_description.

      me->_set_properties(
        EXPORTING
          i_function_module = i_function_module
          i_transport_request = i_transport_request
          i_s_func_data       = ls_func_data
        IMPORTING
          e_error_description = DATA(l_error_description)
          e_success           = DATA(l_properties_updated)
      ).

      IF l_properties_updated = abap_false.

        r_response = |Function Module { i_function_module } source code updated but the description was not.|.

        IF l_error_description IS NOT INITIAL.
          r_response = |{ r_response }Error: { l_error_description }|.
        ENDIF.

        me->_unlock( i_function_module ).

        RETURN.

      ENDIF.

    ENDIF.

    me->_unlock( i_function_module ).

    r_response = |Function Module { i_function_module } updated successfully!|.

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

    DATA(l_function_module) = i_function_module.

    l_function_module = to_lower( condense( l_function_module ) ).

    lt_checkrun_objects = VALUE #( ( object_reference-uri = |{ mc_uri }/{ l_function_module }|
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
      r_response = |The function module { l_function_module } has no syntax errors.|.
      RETURN.
    ENDIF.

    DATA(l_syntax_errors_found) = |The function module { l_function_module } has syntax errors.|.

    r_response = l_syntax_errors_found &&
                 cl_abap_char_utilities=>newline &&
                 cl_abap_char_utilities=>newline &&
                 r_response.

  ENDMETHOD.

  METHOD activate.

    DATA: lt_objects   TYPE STANDARD TABLE OF dwinactiv,
          ls_object    TYPE dwinactiv,
          lv_no_force  TYPE boole_d,
          lo_checklist TYPE REF TO cl_wb_checklist.

    DATA(l_function_module) = i_function_module.

    l_function_module = to_upper( condense( l_function_module ) ).

    SELECT SINGLE @abap_true
      FROM tfdir
      WHERE funcname = @l_function_module
      INTO @DATA(l_exists).

    IF sy-subrc <> 0.
      r_response = |Function Module { i_function_module } not found.|.
      RETURN.
    ENDIF.

    DATA(l_has_errors) = abap_false.

    r_response = me->check_syntax( l_function_module ).

    LOOP AT me->_t_check_run_reports ASSIGNING FIELD-SYMBOL(<ls_check_run_report>).
      IF <ls_check_run_report>-results IS NOT INITIAL.
        l_has_errors = abap_true.
        EXIT.
      ENDIF.
    ENDLOOP.

    IF l_has_errors = abap_true.
      DATA(l_response) = |Error(s) found while activating the function module { l_function_module }.{ cl_abap_char_utilities=>newline }|.
      r_response = l_response && r_response.
      RETURN.
    ENDIF.

    ls_object-object   = me->mc_object_function.
    ls_object-obj_name = l_function_module.

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
      r_response = |Error while activating the function module { l_function_module }.|.
      RETURN.
    ENDIF.

    lo_checklist->get_error_messages(
      IMPORTING
        p_error_tab = DATA(lt_errors)                 " Error Message Table
    ).

    LOOP AT lt_errors ASSIGNING FIELD-SYMBOL(<ls_error>).

      IF sy-tabix = 1.
        r_response = |Error(s) while activating the function module { l_function_module }.{ cl_abap_char_utilities=>newline }|.
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

    IF me->_is_active( l_function_module ) = abap_true.

      r_response = |function module { l_function_module } activated.|.

    ENDIF.

  ENDMETHOD.

  METHOD _is_authorized.

    "Mode ('INSERT','MODIFY','SHOW','FREE')

    r_authorized = abap_true.

    CALL FUNCTION 'RS_ACCESS_PERMISSION'
      EXPORTING
        mode                     = i_mode
        object                   = to_upper( condense( i_function_module ) )
        object_class             = mc_object_function
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

  METHOD _get_source_code.

    DATA: ls_request  TYPE sadt_rest_request,
          ls_response TYPE sadt_rest_response.

    DATA l_function_group_name TYPE string.

    DATA(l_function_module) = to_lower( condense( i_function_module ) ).

    DATA(l_function_group) = me->_get_function_group( i_function_module ).

    l_function_group_name = to_lower( condense( l_function_group ) ).

    ls_request-request_line-method = 'GET'.
    ls_request-request_line-uri = |{ me->mc_uri }/{ l_function_module }/source/main|.
    ls_request-request_line-version = 'HTTP/1.1'.

    REPLACE '&1' IN ls_request-request_line-uri WITH l_function_group_name.

    ls_request-header_fields = VALUE #( ( name = 'Accept'
                                          value = 'text/plain' ) ).

    CALL FUNCTION 'SADT_REST_RFC_ENDPOINT'
      EXPORTING
        request  = ls_request
      IMPORTING
        response = ls_response.

    r_source = cl_abap_codepage=>convert_from( source = ls_response-message_body ).

  ENDMETHOD.

  METHOD _get_function_group.

    CLEAR r_function_group.

    DATA(l_function_module) = to_upper( condense( i_function_module ) ).

    SELECT SINGLE funcname, pname, include
      FROM tfdir
      WHERE funcname = @l_function_module
      INTO @DATA(ls_tfdir).

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    CALL FUNCTION 'FUNCTION_INCLUDE_CONCATENATE'
      CHANGING
        program                  = ls_tfdir-pname
        complete_area            = r_function_group
      EXCEPTIONS
        not_enough_input         = 0
        no_function_pool         = 0
        delimiter_wrong_position = 0
        OTHERS                   = 0.

  ENDMETHOD.

  METHOD _get_properties.

    DATA: ls_request  TYPE sadt_rest_request,
          ls_response TYPE sadt_rest_response,
          ls_exc_data TYPE sadt_exception.

    DATA l_langu TYPE t002-laiso.

    CLEAR e_s_func_data.

    DATA(l_function_module) = to_lower( condense( i_function_module ) ).

    DATA(l_function_group) = me->_get_function_group( i_function_module ).

    DATA(l_function_group_name) = to_lower( condense( l_function_group ) ).

    ls_request-request_line-method = 'GET'.
    ls_request-request_line-uri = |{ me->mc_uri }/{ l_function_module }|.
    ls_request-request_line-version = 'HTTP/1.1'.

    REPLACE '&1' IN ls_request-request_line-uri WITH l_function_group_name.

    ls_request-header_fields = VALUE #( ( name = 'Accept'
                                          value = 'application/vnd.sap.adt.functions.fmodules.v2+xml' ) ).

    CALL FUNCTION 'SADT_REST_RFC_ENDPOINT'
      EXPORTING
        request  = ls_request
      IMPORTING
        response = ls_response.

    IF ls_response-message_body IS INITIAL.
      RETURN.
    ENDIF.

    TRY.

        CALL TRANSFORMATION st_fb_adt_func
          SOURCE XML ls_response-message_body
          RESULT func_data = e_s_func_data.

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

    DATA(l_function_module) = to_lower( condense( i_function_module ) ).
    DATA(l_transport_request) = to_upper( condense( i_transport_request ) ).

    ls_request-request_line-method = 'PUT'.
    ls_request-request_line-uri = |{ me->mc_uri }/{ l_function_module }?lockHandle={ me->_lock_handle }&corrNr={ l_transport_request }|.
    ls_request-request_line-version = 'HTTP/1.1'.

    ls_request-header_fields = VALUE #( ( name = 'Accept'
                                          value = 'application/vnd.sap.adt.checkmessages+xml' )

                                        ( name = 'Content-Type'
                                          value = 'application/vnd.sap.adt.functions.fmodules.v2+xml' ) ).

    TRY.

        CALL TRANSFORMATION st_fb_adt_func
          SOURCE func_data = i_s_func_data
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

  METHOD _lock.

    DATA: ls_request     TYPE sadt_rest_request,
          ls_response    TYPE sadt_rest_response,
          ls_lock_result TYPE sadt_object_lock_result2.

    DATA(l_function_module) = to_lower( condense( i_function_module ) ).

    DATA(l_function_group) = me->_get_function_group( i_function_module ).

    DATA(l_function_group_name) = to_lower( condense( l_function_group ) ).

    ls_request-request_line-method = 'POST' ##NO_TEXT.
    ls_request-request_line-uri = |{ me->mc_uri }/{ l_function_module }?_action=LOCK&accessMode=MODIFY|.
    ls_request-request_line-version = 'HTTP/1.1' ##NO_TEXT.

    REPLACE '&1' IN ls_request-request_line-uri WITH l_function_group_name.

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

    DATA(l_function_module) = to_lower( condense( i_function_module ) ).

    DATA(l_function_group) = me->_get_function_group( i_function_module ).

    DATA(l_function_group_name) = to_lower( condense( l_function_group ) ).

    ls_request-request_line-method = 'POST' ##NO_TEXT.
    ls_request-request_line-uri = |{ me->mc_uri }/{ l_function_module }?_action=UNLOCK&lockHandle={ me->_lock_handle }| ##NO_TEXT.
    ls_request-request_line-version = 'HTTP/1.1' ##NO_TEXT.

    REPLACE '&1' IN ls_request-request_line-uri WITH l_function_group_name.

    CALL FUNCTION 'SADT_REST_RFC_ENDPOINT'
      EXPORTING
        request  = ls_request
      IMPORTING
        response = ls_response.

  ENDMETHOD.

  METHOD _is_active.

    DATA: lt_messages TYPE STANDARD TABLE OF sprot_u WITH DEFAULT KEY,
          lt_e071     TYPE STANDARD TABLE OF e071 WITH DEFAULT KEY.

    DATA ls_e071 TYPE e071.

    ls_e071-object   = mc_object.
    ls_e071-obj_name = to_upper( condense( i_function_module ) ).
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

  METHOD _deserialize_check_run_reports.

    TRY.

        CALL TRANSFORMATION st_adt_check_run_reports
          SOURCE XML i_xml
          RESULT checkrunreports = et_check_run_reports.

      CATCH cx_transformation_error.
        RETURN.
    ENDTRY.

  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.

    DATA l_response TYPE string.
    DATA l_source TYPE string.

    DATA(l_create) = abap_false.
    DATA(l_read) = abap_false.
    DATA(l_search) = abap_false.
    DATA(l_update) = abap_false.
    DATA(l_check) = abap_false.
    DATA(l_activate) = abap_true.
    DATA(l_get_function_group) = abap_false.
    DATA(l_get_source_code) = abap_false.
    DATA(l_get_properties) = abap_false.


    CASE abap_true.

      WHEN l_create.

        l_response = me->create(
                       i_function_module   = 'Z_F_YAAI_FC_TST1_2'
                       i_short_description = 'ADT API Test'
                       i_function_group    = 'ZFG_YAAI_FC_TST1'
                       i_transport_request = 'NPLK900125'
                     ).

      WHEN l_read.

        l_response = me->read(
          EXPORTING
            i_function_module = 'RPY_FUNCTIONMODULE_READ_NEW'
        ).

      WHEN l_search.

        l_response = me->search(
                       i_package           = '$TMP'
*                       i_function_module   =
*                       i_short_description =
                     ).

      WHEN l_update.

        l_source = 'FUNCTION Z_F_YAAI_FC_TST1_2'.
        l_source = |{ l_source }{ cl_abap_char_utilities=>newline }  IMPORTING|.
        l_source = |{ l_source }{ cl_abap_char_utilities=>newline }    i1 TYPE i|.
        l_source = |{ l_source }{ cl_abap_char_utilities=>newline }    i2 TYPE string|.
        l_source = |{ l_source }{ cl_abap_char_utilities=>newline }  EXPORTING|.
        l_source = |{ l_source }{ cl_abap_char_utilities=>newline }    e1 TYPE i.|.
        l_source = |{ l_source }{ cl_abap_char_utilities=>newline }    e1 = i1.|.
        l_source = |{ l_source }{ cl_abap_char_utilities=>newline }|.
        l_source = |{ l_source }{ cl_abap_char_utilities=>newline }ENDFUNCTION.|.

        l_response = me->update(
                       i_function_module   = 'Z_F_YAAI_FC_TST1_2'
*                       i_short_description =
                       i_transport_request = 'NPLK900125'
                       i_source            = l_source
                     ).

      WHEN l_get_function_group.

        DATA(l_fg) = me->_get_function_group( i_function_module = 'Z_F_YAAI_FC_TST1_1' ).

        l_response = l_fg.


      WHEN l_get_source_code.

        l_response = me->_get_source_code( 'Z_F_YAAI_FC_TST1_1' ).

      WHEN l_get_properties.

        me->_get_properties(
          EXPORTING
            i_function_module = 'Z_F_YAAI_FC_TST1_1'
          IMPORTING
            e_error_message   = DATA(l_error_message)
            e_s_func_data     = DATA(ls_func_data)
        ).

        IF l_error_message IS INITIAL.
          l_response = ls_func_data-description.
        ELSE.
          l_response = l_error_message.
        ENDIF.

      WHEN l_check.

        l_response = me->check_syntax(
          EXPORTING
            i_function_module = 'Z_F_YAAI_FC_TST1_1'
        ).

      WHEN l_activate.

        l_response = me->activate(
          EXPORTING
            i_function_module = 'Z_F_YAAI_FC_TST1_1'
        ).

    ENDCASE.

    out->write( l_response ).

  ENDMETHOD.

ENDCLASS.
